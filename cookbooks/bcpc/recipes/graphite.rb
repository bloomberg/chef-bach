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

include_recipe 'bcpc::default'
include_recipe 'bcpc::apache2'
include_recipe 'bcpc::mysql_client'
include_recipe 'bcpc::mysql_data_bags'

#
# These data bags and vault items are pre-populated at compile time by
# the bcpc::mysql_data_bags recipe.
#
root_user = get_config!('mysql-root-user')
root_password = get_config!('password', 'mysql-root', 'os')

graphite_user = get_config!('mysql-graphite-user')
graphite_password = get_config!('password', 'mysql-graphite', 'os')

%w{
  python-dev
  python-pytz
  python-mysqldb
  python-pip
  python-cairo
  python-django-tagging
  python-ldap
  python-twisted
  python-memcache
  python-pyparsing
  python-scandir
  libcairo2-dev
  libffi-dev
}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

package 'python-django' do
  action :upgrade
  version node[:bcpc][:graphite][:django][:version] 
end

%w{
  python-whisper
  python-carbon
  python-graphite-web
}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w{
  cache
  relay
  aggregator
}.each do |pkg|
  template "/etc/init.d/carbon-#{pkg}" do
    source 'carbon/init.erb'
    owner 'root'
    group 'root'
    mode 00755
    notifies :restart, "service[carbon-#{pkg}]", :delayed
    variables( :daemon => "#{pkg}" )
  end
  
  service "carbon-#{pkg}" do
    action [ :enable, :start ]
  end
end

mysql_servers =
  get_node_attributes(MGMT_IP_GRAPHITE_WEBPORT_ATTR_SRCH_KEYS,'mysql','bcpc')

# Directory resource sets owner and group only to the leaf directory.
# All other directories will be owned by root
directory node['bcpc']['graphite']['local_storage_dir'].to_s do
  owner 'www-data'
  group 'www-data'
  recursive true
end

directory node['bcpc']['graphite']['local_log_dir'].to_s do
  owner 'www-data'
  group 'www-data'
  recursive true
end

directory node['bcpc']['graphite']['local_data_dir'].to_s do
  owner 'www-data'
  group 'www-data'
  recursive true
end

directory "#{node['bcpc']['graphite']['local_log_dir']}/webapp" do
  owner 'www-data'
  group 'www-data'
end

['info.log', 'exception.log' ].each do |f|
  file "#{node['bcpc']['graphite']['local_log_dir']}/webapp/#{f}" do
    owner 'www-data'
    group 'www-data'
  end
end

template '/opt/graphite/conf/carbon.conf' do
  source 'carbon/carbon.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables(
    :servers => mysql_servers,
    :min_quorum => mysql_servers.length/2 + 1 )
  notifies :restart, 'service[carbon-cache]', :delayed
  notifies :restart, 'service[carbon-aggregator]', :delayed
  notifies :restart, 'service[carbon-relay]', :delayed
end

template '/opt/graphite/conf/storage-schemas.conf' do
  source 'carbon/storage-schemas.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :restart, 'service[carbon-cache]', :delayed
end

template '/opt/graphite/conf/storage-aggregation.conf' do
  source 'carbon/storage-aggregation.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :restart, 'service[carbon-cache]', :delayed
end

template '/opt/graphite/conf/relay-rules.conf' do
  source 'carbon/relay-rules.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables( :servers => mysql_servers )
  notifies :restart, 'service[carbon-relay]', :delayed
end

template '/opt/graphite/conf/aggregation-rules.conf' do
  source 'carbon/aggregation-rules.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :restart, 'service[carbon-aggregator]', :delayed
end

template '/opt/graphite/conf/rewrite-rules.conf' do
  source 'carbon/rewrite-rules.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
end

#
# a2ensite for httpd 2.4 (Ubuntu 14.04) expects the file to end in '.conf'
# a2ensite for httpd 2.2 (Ubuntu 12.04) expects it NOT to end in '.conf'
#
graphite_web_conf_file =
  if Gem::Version.new(node[:lsb][:release]) >= Gem::Version.new('14.04')
    '/etc/apache2/sites-available/graphite-web.conf'
  else
    '/etc/apache2/sites-available/graphite-web'
  end

template graphite_web_conf_file do
  source 'apache-graphite-web.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :restart, 'service[apache2]', :delayed
end

bash 'apache-enable-graphite-web' do
  user 'root'
  code 'a2ensite graphite-web'
  not_if 'test -r /etc/apache2/sites-enabled/graphite-web*'
  notifies :restart, 'service[apache2]', :delayed
end

template '/opt/graphite/conf/graphite.wsgi' do
  source 'graphite/wsgi.erb'
  owner 'root'
  group 'root'
  mode 00755
end

template '/opt/graphite/webapp/graphite/local_settings.py' do
  source 'graphite/local_settings.py.erb'
  owner 'root'
  group 'www-data'
  mode 00440
  variables(
    :servers => mysql_servers,
    :min_quorum => mysql_servers.length/2 + 1 )
  notifies :restart, 'service[apache2]', :delayed
end

mysql_database node[:bcpc][:graphite_dbname] do
  connection mysql_local_connection_info
  action :create
  notifies :run, 'execute[graphite-database-sync]'
end

[
  '%',
  'localhost'
].each do |host_name|
  mysql_database_user graphite_user do
    connection mysql_local_connection_info
    host host_name
    password graphite_password
    action :create
  end

  mysql_database_user graphite_user do
    connection mysql_local_connection_info
    database_name node[:bcpc][:graphite_dbname]
    host host_name
    privileges ['ALL PRIVILEGES']
    action :grant
  end
end

execute 'graphite-database-sync' do
  action :nothing
  user 'root'
  command <<-EOH
    export PYTHONPATH='/opt/graphite/webapp'
    export DJANGO_SETTINGS_MODULE='graphite.settings'
    python /opt/graphite/bin/django-admin.py syncdb --noinput
    python /opt/graphite/bin/django-admin.py createsuperuser \
      --username=admin --email=#{node[:bcpc][:admin_email]} --noinput
    python /opt/graphite/bin/django-admin.py collectstatic --noinput
    python /opt/graphite/bin/django-admin.py migrate --settings=graphite.settings
  EOH
  notifies :restart, 'service[apache2]', :immediately
end

bash 'cleanup-old-whisper-files' do
  action :run
  user "root"
  code "find #{node['bcpc']['graphite']['local_data_dir']} " \
    "-name '*.wsp' " \
    "-mtime +#{node['bcpc']['graphite']['data']['retention']} " \
    '-type f -exec rm {} \\;'
end

bash 'cleanup-old-logs' do
  action :run
  user "root"
  code "find #{node['bcpc']['graphite']['local_log_dir']} " \
    "-name '*.log*' " \
    "-mtime +#{node['bcpc']['graphite']['log']['retention']} " \
    '-type f -exec rm {} \\;'
end
