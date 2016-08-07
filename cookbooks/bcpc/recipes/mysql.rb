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

include_recipe 'bcpc::default'
include_recipe 'bcpc::mysql_client'
include_recipe 'bcpc::mysql_data_bags'

#
# These data bags and vault items are pre-populated at compile time by
# the bcpc::mysql_data_bags recipe.
#
check_user = get_config!('mysql-check-user')
check_password = get_config!('password', 'mysql-check', 'os')

galera_user = get_config!('mysql-galera-user')
galera_password = get_config!('password', 'mysql-galera', 'os')

root_user = get_config!('mysql-root-user')
#
# The value in the databag should ALWAYS be root.
# If it is not, warn the user and bail out.
#
if root_user != 'root'
  raise 'mysql-root-user is not "root" ! ' \
    'This would have unpredictable effects in this version of chef-bach!'
end
root_password = get_config!('password', 'mysql-root', 'os')

#
# Since the root password is set in debconf before the package is
# installed, Percona XtraDB will come up with the password already
# set for the root user.
#
package 'debconf-utils'

[
  'root_password',
  'root_password_again'
].each do |preseed_item|
  execute "percona-preseed-#{preseed_item}" do
    command 'echo "percona-xtradb-cluster-server-5.6 ' \
      "percona-xtradb-cluster-server/#{preseed_item} " \
      "password #{root_password}\" | debconf-set-selections"
    sensitive true if respond_to?(:sensitive)
  end
end

directory '/etc/mysql' do
  owner 'root'
  group 'root'
  mode 00755
end

template '/etc/mysql/my.cnf' do
  source 'mysql/my.cnf.erb'
  mode 00644
  notifies :reload, 'service[mysql]', :delayed
end

template '/etc/mysql/debian.cnf' do
  source 'mysql/my-debian.cnf.erb'
  mode 00644
  notifies :reload, 'service[mysql]', :delayed
end

directory '/etc/mysql/conf.d' do
  owner 'root'
  group 'root'
  mode 00755
end

apt_package 'percona-xtradb-cluster-56' do
  #
  # This is an ":install" and not an ":upgrade" to avoid momentary
  # disruptions in the event of a chef run when only a bare quorum is
  # available.
  #
  # In theory, all 5.6.x revisions should be compatible, so adding new
  # cluster members with a different subversion should be OK.
  #
  action :install
  options '-o Dpkg::Options::="--force-confdef" ' \
          '-o Dpkg::Options::="--force-confold"'
end

service 'mysql' do
  action [:enable, :start]
end

[
  'localhost',
  '%'
].each do |host_name|
  mysql_database_user galera_user do
    connection mysql_local_connection_info
    host host_name
    password galera_password
    action :create
  end

  mysql_database_user galera_user do
    connection mysql_local_connection_info
    host host_name
    privileges ['ALL PRIVILEGES']
    action :grant
  end

  mysql_database_user galera_user do
    connection mysql_local_connection_info
    host host_name
    database_name '*.*'
    privileges ['ALL PRIVILEGES']
    action :grant
  end
end

mysql_database_user check_user do
  connection mysql_local_connection_info
  host 'localhost'
  password check_password
  action :create
end

mysql_database_user check_user do
  connection mysql_local_connection_info
  privileges ['PROCESS']
  action :grant
end

#
# We re-create the root user with host '%' so that it is usable over
# remote TCP sessions.
#
mysql_database_user root_user do
  connection mysql_local_connection_info
  host '%'
  password root_password
  action :create
end

mysql_database_user root_user do
  connection mysql_local_connection_info
  privileges ['ALL PRIVILEGES']
  grant_option true
  action :grant
end

mysql_database_user root_user do
  connection mysql_local_connection_info
  database_name '*.*'
  privileges ['ALL PRIVILEGES']
  grant_option true
  action :grant
end

mysql_nodes = get_nodes_for('mysql', 'bcpc')
all_nodes = get_all_nodes
max_connections =
  [
    (mysql_nodes.length * 50 + all_nodes.length * 5),
    200
  ].max
pool_size = node['bcpc']['mysql']['innodb_buffer_pool_size']

template '/etc/mysql/conf.d/wsrep.cnf' do
  source 'mysql/wsrep.cnf.erb'
  mode 00644
  variables(max_connections: max_connections,
            innodb_buffer_pool_size: pool_size,
            servers: mysql_nodes)
  notifies :stop, 'service[mysql]', :immediate
  notifies :start, 'service[mysql]', :immediate
end

# #
# # I can't tell what this code was meant to do.  The bare gcomm://
# # will only exist as long as no other cluster members have
# # converged, so why would I want to replace it?
# #
# # Additionally, wsrep_urls has been replaced in modern versions.
# # I don't think this code has functioned for some years.
# #
# bash "remove-bare-gcomm" do
#   action :nothing
#   user "root"
#   code <<-EOH
#     sed --in-place 's/^\\(wsrep_urls=.*\\),gcomm:\\/\\/"/\\1"/' \
#       /etc/mysql/conf.d/wsrep.cnf
#   EOH
# end

ruby_block 'Check MySQL Quorum Status' do
  block do
    require 'mysql2'
    require 'timeout'

    # Returns 'ON' if wsrep is ready.
    # Returns 'nil' if we time out or get an error.
    def wsrep_ready_value(client_options)
      Timeout.timeout(5) do
        client = Mysql2::Client.new(client_options)
        result = client.query("SHOW GLOBAL STATUS LIKE 'wsrep_ready'")
        result.first['Value']
      end
    rescue
      nil
    end

    mysql_status = nil
    poll_attempts = 10

    poll_attempts.times do |i|
      mysql_status = wsrep_ready_value(mysql_local_connection_info)
      if mysql_status == 'ON'
        Chef::Log.info("MySQL is up after #{i} poll attempts")
        break
      else
        Chef::Log.debug("MySQL status is #{mysql_status.inspect}, sleeping")
        sleep(0.5)
      end
    end

    unless mysql_status == 'ON'
      raise 'MySQL wsrep status still not ready after ' \
        "#{poll_attempts} poll attempts! (got: #{mysql_status.inspect})"
    end
  end
end

package 'xinetd' do
  action :upgrade
end

service 'xinetd' do
  action [:enable, :start]
end

replace_or_add 'add-mysqlchk-to-etc-services' do
  path '/etc/services'
  pattern '^mysqlchk'
  line "mysqlchk\t3307/tcp"
end

template '/etc/xinetd.d/mysqlchk' do
  source 'mysql/xinetd-mysqlchk.erb'
  owner 'root'
  group 'root'
  mode 00440
  notifies :restart, 'service[xinetd]', :immediately
end

