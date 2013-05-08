#
# Cookbook Name:: bcpc
# Recipe:: mysql
#
# Copyright 2013, Bloomberg L.P.
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

ruby_block "initialize-mysql-config" do
    block do
        make_config('mysql-root-user', "root")
        make_config('mysql-root-password', secure_password)
        make_config('mysql-galera-user', "sst")
        make_config('mysql-galera-password', secure_password)
    end
end

apt_repository "percona" do
    uri node['bcpc']['repos']['mysql']
    distribution node['lsb']['codename']
    components ["main"]
    key "percona-release.key"
end

bash "workaround-mysql-deps-problem" do
    user "root"
    code <<-EOH
        VERSION=`apt-cache policy libmysqlclient18 | grep -B1 percona | head -1 | awk '{print $1}'`
        DEBIAN_FRONTEND=noninteractive apt-get -y install libmysqlclient18=$VERSION
    EOH
    not_if "dpkg -l |grep libmysqlclient18"
end

package "percona-xtradb-cluster-server-5.5" do
    action :upgrade
end

ruby_block "initial-mysql-config" do
    block do
        if not system "mysql -uroot -p#{get_config('mysql-root-password')} -e 'SELECT user from mysql.user where User=\"haproxy\"'" then
            %x[ mysql -u root -e "UPDATE mysql.user SET password=PASSWORD('#{get_config('mysql-root-password')}') WHERE user='root'; FLUSH PRIVILEGES;"
                mysql -u root -p#{get_config('mysql-root-password')} -e "UPDATE mysql.user SET host='%' WHERE user='root' and host='localhost'; FLUSH PRIVILEGES;"
                mysql -u root -p#{get_config('mysql-root-password')} -e "GRANT USAGE ON *.* to #{get_config('mysql-galera-user')}@'%' IDENTIFIED BY '#{get_config('mysql-galera-password')}';"
                mysql -u root -p#{get_config('mysql-root-password')} -e "GRANT ALL PRIVILEGES on *.* TO #{get_config('mysql-galera-user')}@'%' IDENTIFIED BY '#{get_config('mysql-galera-password')}';"
                mysql -u root -p#{get_config('mysql-root-password')} -e "INSERT INTO mysql.user (Host,User) VALUES ('%','haproxy');"
                mysql -u root -p#{get_config('mysql-root-password')} -e "FLUSH PRIVILEGES;"
            ]
        end
    end
end

directory "/etc/mysql" do
    owner "root"
    group "root"
    mode 00755
end

template "/etc/mysql/my.cnf" do
    source "my.cnf.erb"
    mode 00644
    notifies :restart, "service[mysql]", :delayed
end

template "/etc/mysql/debian.cnf" do
    source "my-debian.cnf.erb"
    mode 00644
    notifies :restart, "service[mysql]", :delayed
end

directory "/etc/mysql/conf.d" do
    owner "root"
    group "root"
    mode 00755
end

template "/etc/mysql/conf.d/wsrep.cnf" do
    source "wsrep.cnf.erb"
    mode 00644
    notifies :restart, "service[mysql]", :immediately
    results = get_head_nodes
    # If we are the first one, special case
    seed = ""
    if ((results.length == 1) && (results[0].hostname == node.hostname)) then
        seed = "gcomm://"
        # Commented out to prevent mysql from always restarting when 1 head-node
        notifies :run, "bash[remove-bare-gcomm]", :delayed
    end
    variables( :seed => seed,
               :servers => results )
end

bash "remove-bare-gcomm" do
    action :nothing
    user "root"
    code <<-EOH
        sed --in-place 's/^\\(wsrep_urls=.*\\),gcomm:\\/\\/"/\\1"/' /etc/mysql/conf.d/wsrep.cnf
    EOH
end

service "mysql" do
    action [ :enable, :start ]
    start_command "service mysql start || true"
end
