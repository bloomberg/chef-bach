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

include_recipe "bcpc::mysql"
include_recipe "bcpc::apache2"

make_config('mysql-zabbix-user','zabbix')

# backward compatibility
mysql_zabbix_password = get_config("mysql-zabbix-password")
if mysql_zabbix_password.nil?
  mysql_zabbix_password = secure_password
end

bootstrap = get_bootstrap
results = get_nodes_for("zabbix-head").map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results

chef_vault_secret "mysql-zabbix" do
  data_bag 'os'
  raw_data({ 'password' => mysql_zabbix_password })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

make_config('zabbix-admin-user', "admin")

zabbix_admin_password = get_config("zabbix-admin-password")
if zabbix_admin_password.nil?
  zabbix_admin_password = secure_password
end

chef_vault_secret "zabbix-admin" do
  data_bag 'os'
  raw_data({ 'password' => zabbix_admin_password })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

make_config('zabbix-guest-user', "guest")

remote_file "/tmp/zabbix-server.tar.gz" do
  source "#{get_binary_server_url}/zabbix-server.tar.gz"
  owner "root"
  mode 00444
  not_if { File.exists?("/usr/local/sbin/zabbix_server") }
end

bash "install-zabbix-server" do
  code "tar zxf /tmp/zabbix-server.tar.gz -C /usr/local/ && rm /tmp/zabbix-server.tar.gz"
  not_if { File.exists?("/usr/local/sbin/zabbix_server") }
end

user node[:bcpc][:zabbix][:user] do
  shell "/bin/false"
  home "/var/log"
  gid node[:bcpc][:zabbix][:group]
  system true
end

directory "/var/log/zabbix" do
  user node[:bcpc][:zabbix][:user]
  group node[:bcpc][:zabbix][:group]
  mode 00755
end

template "/etc/init/zabbix-server.conf" do
  source "upstart-zabbix-server.conf.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :restart, "service[zabbix-server]", :delayed
end

template "/usr/local/etc/zabbix_server.conf" do
  source "zabbix_server.conf.erb"
  owner node[:bcpc][:zabbix][:user]
  group "root"
  mode 00600
  notifies :restart, "service[zabbix-server]", :delayed
end

ruby_block "zabbix-database-creation" do
  block do
    mysql_root_password = get_config!('password','mysql-root','os')
    if not system "mysql -uroot -p#{ mysql_root_password } -e 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"#{node['bcpc']['zabbix_dbname']}\"'|grep \"#{node['bcpc']['zabbix_dbname']}\"" then
      puts %x[ mysql -uroot -p#{ mysql_root_password } -e "CREATE DATABASE #{node['bcpc']['zabbix_dbname']} CHARACTER SET UTF8;"
        mysql -uroot -p#{ mysql_root_password } -e "GRANT ALL ON #{node['bcpc']['zabbix_dbname']}.* TO '#{get_config!('mysql-zabbix-user')}'@'%' IDENTIFIED BY '#{get_config!('password','mysql-zabbix','os')}';"
        mysql -uroot -p#{ mysql_root_password } -e "GRANT ALL ON #{node['bcpc']['zabbix_dbname']}.* TO '#{get_config!('mysql-zabbix-user')}'@'localhost' IDENTIFIED BY '#{get_config!('password','mysql-zabbix','os')}';"
        mysql -uroot -p#{ mysql_root_password } -e "FLUSH PRIVILEGES;"
        mysql -uroot -p#{ mysql_root_password } #{node['bcpc']['zabbix_dbname']} < /usr/local/share/zabbix/schema.sql
        mysql -uroot -p#{ mysql_root_password } #{node['bcpc']['zabbix_dbname']} < /usr/local/share/zabbix/images.sql
        mysql -uroot -p#{ mysql_root_password } #{node['bcpc']['zabbix_dbname']} < /usr/local/share/zabbix/data.sql
        HASH=`echo -n "#{get_config!('password','zabbix-admin','os')}" | md5sum | awk '{print $1}'`
        mysql -uroot -p#{ mysql_root_password } #{node['bcpc']['zabbix_dbname']} -e "UPDATE users SET passwd=\\"$HASH\\" WHERE alias=\\"#{get_config('zabbix-admin-user')}\\";"
        HASH=`echo -n "" | md5sum | awk '{print $1}'`
        mysql -uroot -p#{ mysql_root_password } #{node['bcpc']['zabbix_dbname']} -e "UPDATE users SET passwd=\\"$HASH\\" WHERE alias=\\"#{get_config('zabbix-guest-user')}\\";"
      ]
    end
  end
end

template "/usr/local/share/zabbix/tuning.sql" do
  source "zabbix_tuning.sql.erb"
  variables(
    :history_retention => node['bcpc']['zabbix']['retention_history'],
    :storage_retention => node['bcpc']['zabbix']['retention_default']
  )
  owner "root"
  group "root"
  mode 00644
  notifies :run, "ruby_block[customize-zabbix-config]", :immediately
end

ruby_block "customize-zabbix-config" do
  block do
    puts %x[
      mysql -u#{get_config!('mysql-zabbix-user')} -p#{get_config!('password','mysql-zabbix','os')} #{node['bcpc']['zabbix_dbname']} < /usr/local/share/zabbix/tuning.sql
    ]
  end
  action :nothing
end

template "/usr/local/share/zabbix/leader_election.sql" do
  source "zabbix.leader_election.sql.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :run, "ruby_block[setup-leader-election]", :immediately
end

# Keeping this query out of 'ruby_block "zabbix-database-creation"' so that the
# table can be created on an existing cluster which already has zabbix db
ruby_block "setup-leader-election" do
  block do
    puts %x[
      mysql -u#{get_config!('mysql-zabbix-user')} -p#{get_config!('password','mysql-zabbix','os')} #{node['bcpc']['zabbix_dbname']} < /usr/local/share/zabbix/leader_election.sql 
    ]  
  end
  action :nothing
end

bash "elect_leader" do
  code %Q{ mysql -u#{get_config!('mysql-zabbix-user')} -p#{get_config!('password','mysql-zabbix','os')} #{node['bcpc']['zabbix_dbname']} -e 'call elect_leader(\"#{node[:hostname]}\")' }
  returns [0]
end

service "zabbix-server" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => false
  action [ :enable, :start ]
  subscribes :restart, "ruby_block[customize-zabbix-config]", :delayed
end

%w{traceroute php5-mysql php5-gd}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

file "/etc/php5/apache2/conf.d/zabbix.ini" do
  user "root"
  group "root"
  mode 00644
  content <<-EOH
    post_max_size = 16M
    max_execution_time = 300
    max_input_time = 300
    date.timezone = America/New_York
  EOH
  notifies :run, "ruby_block[run_state_apache2_restart]", :immediate
end

template "/usr/local/share/zabbix/php/conf/zabbix.conf.php" do
  source "zabbix.conf.php.erb"
  user node[:bcpc][:zabbix][:user]
  group "www-data"
  mode 00640
  notifies :run, "ruby_block[run_state_apache2_restart]", :immediate
end

template "/etc/apache2/sites-available/zabbix-web" do
  source "apache-zabbix-web.conf.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :run, "ruby_block[run_state_apache2_restart]", :immediate
end

bash "apache-enable-zabbix-web" do
  user "root"
  code <<-EOH
    a2ensite zabbix-web
  EOH
  not_if "test -r /etc/apache2/sites-enabled/zabbix-web"
  notifies :run, "ruby_block[run_state_apache2_restart]", :immediate
end

include_recipe "bcpc::zabbix-work"

directory "/usr/local/bin/checks" do
  action :create
  owner  node[:bcpc][:zabbix][:user]
  group "root"
  mode 00775
end 

directory "/usr/local/etc/checks" do
  action  :create
  owner  node[:bcpc][:zabbix][:user]
  group "root"
  mode 00775
end 

cookbook_file "/usr/local/bin/check" do
  source "checks/check"
  owner "root"
  mode "00755"
end

ruby_block "run_state_apache2_restart" do
  block do
    node.run_state['restart_apache2_needed'] = true
  end
  action :nothing
end

service "apache2" do
  action :restart
  only_if { node.run_state['restart_apache2_needed']  == true }
end
