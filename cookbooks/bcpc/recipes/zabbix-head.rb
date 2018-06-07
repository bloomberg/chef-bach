#
# Cookbook Name:: bcpc
# Recipe:: zabbix-head
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

include_recipe 'bcpc::apache2'
include_recipe 'bcpc::mysql'
include_recipe 'bcpc::zabbix-repo'

#
# These data bags and vault items are pre-populated at compile time by
# the bcpc::mysql_data_bags recipe.
#
root_user = get_config!('mysql-root-user')
root_password = get_config!('password', 'mysql-root', 'os')

zabbix_user = get_config!('mysql-zabbix-user')
zabbix_password = get_config!('password', 'mysql-zabbix', 'os')

bootstrap = get_bootstrap
admins_list = get_head_node_names
admins_list.push(node[:fqdn]) unless admins_list.include?(node[:fqdn])
admins_list.push(bootstrap) unless bootstrap.nil?

zabbix_admin_user = 'Admin'
make_config('zabbix-admin-user', zabbix_admin_user)

zabbix_admin_password =
  get_config('password','zabbix-admin','os') || secure_password

chef_vault_secret 'zabbix-admin' do
  data_bag 'os'
  raw_data({ 'password' => zabbix_admin_password })
  admins admins_list.join(',')
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

#
# At this point, if we cannot retrieve the pw from the vault, the chef
# run should be aborted.
#
zabbix_admin_password = get_config!('password','zabbix-admin','os')

zabbix_guest_user = 'guest'
make_config('zabbix-guest-user', zabbix_guest_user)

user node[:bcpc][:zabbix][:user] do
  shell '/bin/false'
  home '/var/log'
  gid node[:bcpc][:zabbix][:group]
  system true
end

directory '/var/log/zabbix' do
  user node[:bcpc][:zabbix][:user]
  group node[:bcpc][:zabbix][:group]
  mode 0755
end

# Stop the old service if we find the old service definition
service 'zabbix-server' do
  action :stop
  only_if { File.exist?('/etc/init/zabbix-server.conf') }
end

# Remove the old service definition from the source-based build.
file '/etc/init/zabbix-server.conf' do
  action :delete
end

[
  'zabbix-server-mysql',
  'zabbix-frontend-php'
].each do |package_name|
  package package_name do
    action :upgrade
  end
end

template '/etc/zabbix/zabbix_server.conf' do
  source 'zabbix/server.conf.erb'
  owner node[:bcpc][:zabbix][:user]
  group 'root'
  mode 0600
  notifies :restart, 'service[zabbix-server]', :delayed
end

mysql_database node[:bcpc][:zabbix_dbname] do
  connection mysql_local_connection_info
  encoding 'UTF8'
  action :create
  notifies :run, 'execute[zabbix-create-database]', :immediately
end

[
  '%',
  'localhost'
].each do |host_name|
  mysql_database_user zabbix_user do
    connection mysql_local_connection_info
    host host_name
    password zabbix_password
    action :create
  end

  mysql_database_user zabbix_user do
    connection mysql_local_connection_info
    database_name node[:bcpc][:zabbix_dbname]
    host host_name
    privileges ['ALL PRIVILEGES']
    action :grant
  end
end

execute 'zabbix-create-database' do
  command "gunzip -c /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u #{root_user} " \
    "--password=#{root_password} " \
    "#{node[:bcpc][:zabbix_dbname]}"
  sensitive true if respond_to?(:sensitive)
  action :nothing
end

mysql_database 'zabbix-set-admin-password' do
  connection mysql_local_connection_info
  database_name node[:bcpc][:zabbix_dbname]
  sql "UPDATE users SET passwd=md5('#{zabbix_admin_password}') " \
    "WHERE alias='#{zabbix_admin_user}'"
  action :query
end

mysql_database "zabbix-set-guest-password" do
  connection mysql_local_connection_info
  database_name node[:bcpc][:zabbix_dbname]
  sql "UPDATE users SET passwd=md5('') " \
    "WHERE alias='#{zabbix_guest_user}'"
  action :query
end

[
  'tuning.sql',
  'leader_election.sql'
].each do |file_name|
  install_path = File.join(Chef::Config.file_cache_path, file_name)
  resource_name = "zabbix-run-#{file_name.gsub(/\./,'-')}"

  template install_path do
    source "zabbix/#{file_name}.erb"
    variables(
               :history_retention =>
                 node['bcpc']['zabbix']['retention_history'],
               :storage_retention =>
                 node['bcpc']['zabbix']['retention_default']
             )
    owner 'root'
    group 'root'
    mode 0644
    notifies :run, "execute[#{resource_name}]", :immediately
  end

  execute resource_name do
    command "mysql -u #{root_user} " \
      "--password=#{root_password} " \
      "#{node[:bcpc][:zabbix_dbname]} " \
      "< #{install_path}"
    sensitive true if respond_to?(:sensitive)
    action :nothing
  end
end

ruby_block 'zabbix-elect-leader' do
  block do
    require 'mysql2'
    require 'timeout'

    client_options =
      mysql_local_connection_info.merge(database: node[:bcpc][:zabbix_dbname])

    client =
      Mysql2::Client.new(client_options)

    results = client.query("CALL elect_leader('#{node[:hostname]}')")
    Chef::Log.info('Zabbix leader election results: ' + results.inspect)
  end
end

service 'zabbix-server' do
  action [:enable, :start]
end

%w{traceroute php5-mysql php5-gd}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

file '/etc/php5/apache2/conf.d/zabbix.ini' do
  user 'root'
  group 'root'
  mode 00644
  content <<-EOH
    post_max_size = 16M
    max_execution_time = 300
    max_input_time = 300
    date.timezone = America/New_York
  EOH
  notifies :run, 'ruby_block[run_state_apache2_restart]', :immediate
end

directory '/etc/zabbix/web' do
  mode 0555
  recursive true
end

template '/etc/zabbix/web/zabbix.conf.php' do
  source 'zabbix/zabbix.conf.php.erb'
  user node[:bcpc][:zabbix][:user]
  group 'www-data'
  mode 0640
  notifies :run, 'ruby_block[run_state_apache2_restart]', :immediate
end

#
# a2ensite for httpd 2.4 (Ubuntu 14.04) expects the file to end in '.conf'
# a2ensite for httpd 2.2 (Ubuntu 12.04) expects it NOT to end in '.conf'
#
zabbix_web_conf_file =
  if Gem::Version.new(node[:lsb][:release]) >= Gem::Version.new('14.04')
    '/etc/apache2/sites-available/zabbix-web.conf'
  else
    '/etc/apache2/sites-available/zabbix-web'
  end

template zabbix_web_conf_file do
  source 'apache-zabbix-web.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :run, "ruby_block[run_state_apache2_restart]", :immediate
end

execute 'apache-enable-zabbix-web' do
  user 'root'
  command 'a2ensite zabbix-web'
  not_if 'test -r /etc/apache2/sites-enabled/zabbix-web*'
  notifies :run, 'ruby_block[run_state_apache2_restart]', :immediate
end

include_recipe 'bcpc::zabbix-work'

directory '/usr/local/bin/checks' do
  action :create
  owner node[:bcpc][:zabbix][:user]
  group 'root'
  mode 00775
end

directory '/usr/local/etc/checks' do
  action :create
  owner node[:bcpc][:zabbix][:user]
  group 'root'
  mode 00775
end

cookbook_file '/usr/local/bin/check' do
  source 'checks/check'
  owner 'root'
  mode 0755
end

ruby_block 'run_state_apache2_restart' do
  block do
    node.run_state['restart_apache2_needed'] = true
  end
  action :nothing
end

service 'apache2' do
  action :restart
  only_if { node.run_state['restart_apache2_needed']  == true }
end
