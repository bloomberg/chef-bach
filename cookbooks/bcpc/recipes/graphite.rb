# vim: tabstop=2:shiftwidth=2:softtabstop=2 
#
# Cookbook Name:: bcpc
# Recipe:: graphite
#
# Copyright 2013, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "bcpc::default"
include_recipe "bcpc::apache2"

make_config('mysql-graphite-user', "graphite")
# backward compatibility
mysql_graphite_password = get_config("mysql-graphite-password")
if mysql_graphite_password.nil?
  mysql_graphite_password = secure_password
end

bootstrap = get_bootstrap
results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results

chef_vault_secret "mysql-graphite" do
  data_bag 'os'
  raw_data({ 'password' => mysql_graphite_password })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

# if we are using a dedicated disk create a directory before packages start instaling
if node[:bcpc][:graphite][:graphite_disk] != nil then
  disk_index = node[:bcpc][:hadoop][:disks].index(node[:bcpc][:graphite][:graphite_disk])
  if disk_index == nil then
    Chef::Application.fatal!('node[:bcpc][:graphite][:graphite_disk] specifies a disk not found in node[:bcpc][:hadoop][:disks]!')
  end

  directory "/disk/#{disk_index}/graphite" do
    owner "root"
    group "root"
    recursive false
  end

  link node[:bcpc][:graphite][:install_dir] do
    to "/disk/#{disk_index}/graphite"
    link_type :symbolic
  end
end

%w{python-pytz python-pyparsing python-mysqldb python-pip python-cairo python-django-tagging python-ldap python-twisted python-memcache python-pyparsing}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

package "python-django" do
  action :upgrade
  version node[:bcpc][:graphite][:django][:version] 
end

%w{python-whisper python-carbon python-graphite-web}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w{cache relay}.each do |pkg|
  template "/etc/init.d/carbon-#{pkg}" do
    source "init.d-carbon.erb"
    owner "root"
    group "root"
    mode 00755
    notifies :restart, "service[carbon-#{pkg}]", :delayed
    variables( :daemon => "#{pkg}" )
  end
  service "carbon-#{pkg}" do
    action [ :enable, :start ]
  end
end

# #### #
# Adding this to set the graphite ip
# #### #
ruby_block "graphite_ip" do
  block do
    if (node[:bcpc].attribute?(:graphite) \
      and node[:bcpc][:graphite].attribute?(:ip) \
      and node[:bcpc][:graphite][:ip]) then
      Chef::Log.info("graphite ip = '#{node[:bcpc][:graphite][:ip]}'")
    else
      Chef::Log.info("node[:bcpc][:graphite][:ip] is not set")
      if not node[:bcpc][:management][:vip] then
        Chef::Application.fatal!("No graphite ip or management vip!", 1)
      else
        node.override[:bcpc][:graphite][:ip] = node[:bcpc][:management][:vip]
      end
    end
  end
end

mysql_servers = get_node_attributes(MGMT_IP_GRAPHITE_WEBPORT_ATTR_SRCH_KEYS,"mysql","bcpc")

# Directory resource sets owner and group only to the leaf directory.
# All other directories will be owned by root
directory "#{node['bcpc']['graphite']['local_storage_dir']}" do
  owner "www-data"
  group "www-data"
  recursive true
end

directory "#{node['bcpc']['graphite']['local_log_dir']}" do
  owner "www-data"
  group "www-data"
  recursive true
end

directory "#{node['bcpc']['graphite']['local_data_dir']}" do
  owner "www-data"
  group "www-data"
  recursive true
end

directory "#{node['bcpc']['graphite']['local_log_dir']}/webapp" do
  owner "www-data"
  group "www-data"
end

["info.log", "exception.log" ].each do |f|
  file "#{node['bcpc']['graphite']['local_log_dir']}/webapp/#{f}" do
    owner "www-data"
    group "www-data"
  end
end

template "/opt/graphite/conf/carbon.conf" do
  source "carbon.conf.erb"
  owner "root"
  group "root"
  mode 00644
  variables(
    :servers => mysql_servers,
    :min_quorum => mysql_servers.length/2 + 1 )
  notifies :restart, "service[carbon-cache]", :delayed
  notifies :restart, "service[carbon-relay]", :delayed
end

template "/opt/graphite/conf/storage-schemas.conf" do
  source "carbon-storage-schemas.conf.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[carbon-cache]", :delayed
end

template "/opt/graphite/conf/storage-aggregation.conf" do
  source "carbon-storage-aggregation.conf.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[carbon-cache]", :delayed
end

template "/opt/graphite/conf/relay-rules.conf" do
  source "carbon-relay-rules.conf.erb"
  owner "root"
  group "root"
  mode 00644
  variables( :servers => mysql_servers )
  notifies :restart, "service[carbon-relay]", :delayed
end

template "/etc/apache2/sites-available/graphite-web" do
  source "apache-graphite-web.conf.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[apache2]", :delayed
end

bash "apache-enable-graphite-web" do
  user "root"
  code "a2ensite graphite-web"
  not_if "test -r /etc/apache2/sites-enabled/graphite-web"
  notifies :restart, "service[apache2]", :delayed
end

template "/opt/graphite/conf/graphite.wsgi" do
  source "graphite.wsgi.erb"
  owner "root"
  group "root"
  mode 00755
end

template "/opt/graphite/webapp/graphite/local_settings.py" do
  source "graphite.local_settings.py.erb"
  owner "root"
  group "www-data"
  mode 00440
  variables(
    :servers => mysql_servers,
    :min_quorum => mysql_servers.length/2 + 1 )
  notifies :restart, "service[apache2]", :delayed
end

ruby_block "graphite-database-creation" do
    block do
        mysql_root_password = get_config!('password','mysql-root','os')
        if not system "mysql -uroot -p#{ mysql_root_password } -e 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"#{node['bcpc']['graphite_dbname']}\"'|grep \"#{node['bcpc']['graphite_dbname']}\"" then
            %x[ mysql -uroot -p#{ mysql_root_password } -e "CREATE DATABASE #{node['bcpc']['graphite_dbname']};"
                mysql -uroot -p#{ mysql_root_password } -e "GRANT ALL ON #{node['bcpc']['graphite_dbname']}.* TO '#{get_config('mysql-graphite-user')}'@'%' IDENTIFIED BY '#{get_config!('password','mysql-graphite','os')}';"
                mysql -uroot -p#{ mysql_root_password } -e "GRANT ALL ON #{node['bcpc']['graphite_dbname']}.* TO '#{get_config('mysql-graphite-user')}'@'localhost' IDENTIFIED BY '#{get_config!('password','mysql-graphite','os')}';"
                mysql -uroot -p#{ mysql_root_password } -e "FLUSH PRIVILEGES;"
            ]
            self.notifies :run, "bash[graphite-database-sync]", :immediately
            self.resolve_notification_references
        end
    end
end

bash "graphite-database-sync" do
  action :nothing
  user "root"
  code <<-EOH
    export PYTHONPATH='/opt/graphite/webapp'
    export DJANGO_SETTINGS_MODULE='graphite.settings'
    python /opt/graphite/bin/django-admin.py syncdb --noinput
    python /opt/graphite/bin/django-admin.py createsuperuser --username=admin --email=#{node[:bcpc][:admin_email]} --noinput
    python /opt/graphite/bin/django-admin.py collectstatic --noinput
  EOH
  notifies :restart, "service[apache2]", :immediately
end

bash "cleanup-old-whisper-files" do
  action :run
  user "root"
  code "find #{node['bcpc']['graphite']['local_data_dir']} -name '*.wsp' -mtime +#{node['bcpc']['graphite']['data']['retention']} -type f -exec rm {} \\;"
end

bash "cleanup-old-logs" do
  action :run
  user "root"
  code "find #{node['bcpc']['graphite']['local_log_dir']} -name '*.log*' -mtime +#{node['bcpc']['graphite']['log']['retention']} -type f -exec rm {} \\;"
end
