Chef::Resource.send(:include, Bcpc::OSHelper)
#
# Cookbook Name:: bcpc
# Recipe:: mysql
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

Bcpc::OSHelper.set_config(node, 'mysql-root-user', "root")
Bcpc::OSHelper.set_config(node, 'mysql-root-password', Bcpc::Helper.secure_password)
Bcpc::OSHelper.set_config(node, 'mysql-galera-user', "sst")
Bcpc::OSHelper.set_config(node, 'mysql-galera-password', Bcpc::Helper.secure_password)
Bcpc::OSHelper.set_config(node, 'mysql-check-user', "check")
Bcpc::OSHelper.set_config(node, 'mysql-check-password', Bcpc::Helper.secure_password)

apt_repository "percona" do
  uri node['bcpc']['repos']['mysql']
  distribution node['lsb']['codename']
  components ["main"]
  key "percona-release.key"
end

package "percona-xtradb-cluster-server" do
    action :upgrade
end

bash "initial-mysql-config" do
  code <<-EOH
        mysql -u root -e "DROP USER ''@'localhost';
                          GRANT USAGE ON *.* to '#{Bcpc::OSHelper.get_config(node, 'mysql-galera-user')}'@'%' IDENTIFIED BY '#{Bcpc::OSHelper.get_config(node, 'mysql-galera-password')}';
                          GRANT ALL PRIVILEGES on *.* TO '#{Bcpc::OSHelper.get_config(node, 'mysql-galera-user')}'@'%' IDENTIFIED BY '#{Bcpc::OSHelper.get_config(node, 'mysql-galera-password')}';
                          GRANT PROCESS ON *.* to '#{Bcpc::OSHelper.get_config(node, 'mysql-check-user')}'@'localhost' IDENTIFIED BY '#{Bcpc::OSHelper.get_config(node, 'mysql-check-password')}';
                          UPDATE mysql.user SET password=PASSWORD('#{Bcpc::OSHelper.get_config(node, 'mysql-root-password')}') WHERE user='root'; FLUSH PRIVILEGES;
                          UPDATE mysql.user SET host='%' WHERE user='root' and host='localhost';
                          FLUSH PRIVILEGES;"
        EOH
  only_if "mysql -u root -e 'SELECT COUNT(*) FROM mysql.user'"
end

directory "/etc/mysql" do
  owner "root"
  group "root"
  mode 00755
end

template "/etc/mysql/my.cnf" do
  source "my.cnf.erb"
  mode 00644
  notifies :reload, "service[mysql]", :delayed
end

template "/etc/mysql/debian.cnf" do
  source "my-debian.cnf.erb"
  mode 00644
  helpers(Bcpc::OSHelper)
  notifies :reload, "service[mysql]", :delayed
end

directory "/etc/mysql/conf.d" do
  owner "root"
  group "root"
  mode 00755
end

template "/etc/mysql/conf.d/wsrep.cnf" do
  source "wsrep.cnf.erb"
  mode 00644
  helpers(Bcpc::OSHelper)
  variables( :max_connections => [Bcpc::OSHelper.get_nodes_for('mysql',node,'bcpc').length*50+Bcpc::OSHelper.get_all_nodes(node).length*5, 200].max,
             :servers => Bcpc::OSHelper.get_nodes_for('mysql',node,'bcpc') )
  notifies :restart, "service[mysql]", :immediate
end

bash "remove-bare-gcomm" do
  action :nothing
  user "root"
  code <<-EOH
    sed --in-place 's/^\\(wsrep_urls=.*\\),gcomm:\\/\\/"/\\1"/' /etc/mysql/conf.d/wsrep.cnf
  EOH
end

service "mysql" do
  supports :status => true, :restart => true, :reload => false
  action [ :enable, :start ]
end

ruby_block "Check MySQL Quorum Status" do
  status_cmd="mysql -u root -p#{Bcpc::OSHelper.get_config(node, 'mysql-root-password')} -e \"SHOW STATUS LIKE 'wsrep_ready' \\G\" | grep -v 'Value: OFF'"
  iter = 0
  poll_time = 0.5
  block do
    status=`#{status_cmd}`
    while $?.to_i
      status=`#{status_cmd}`
      if $?.to_i != 0 and iter < 10
        sleep(poll_time)
        iter += 1
        Chef::Log.debug("MySQL is down #{iter*poll_time} seconds - #{status}")
      elsif $?.to_i != 0
        raise Chef::Application.fatal! "MySQL is not in a ready state per wsrep_ready for #{iter*poll_time} seconds!"
      else
        Chef::Log.debug("MySQL status is not failing - #{status}")
      end
    end
    Chef::Log.info("MySQL is up after #{iter*poll_time} seconds - #{status}")
  end
  not_if "#{status_cmd}"
end

package "xinetd" do
  action :upgrade
end

bash "add-mysqlchk-to-etc-services" do
  user "root"
  code <<-EOH
    printf "mysqlchk\t3307/tcp\n" >> /etc/services
    EOH
  not_if "grep mysqlchk /etc/services"
end

template "/etc/xinetd.d/mysqlchk" do
  source "xinetd-mysqlchk.erb"
  owner "root"
  group "root"
  mode 00440
  helpers(Bcpc::OSHelper)
  notifies :reload, "service[xinetd]", :immediately
end

service "xinetd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
