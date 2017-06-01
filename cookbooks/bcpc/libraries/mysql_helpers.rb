#
# Cookbook Name:: bcpc
# MySQL Helpers
#
# Copyright 2016, Bloomberg Finance L.P.
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

#
# Returns a configuration hash suitable for use with mysql2 or the
# database cookbook's providers, using a local socket to connect.
#


def mysql_local_connection_info(category='root')
  #
  # The passwords are ALWAYS stored in a data bag. Sometimes the users
  # are not.  If there's no data bag item, use the category name.
  #
  node.run_state["bcpc_mysql_#{category}_username"] ||=
    (get_config("mysql-#{category}-user") || category)

  #
  # The password may be in an unencrypted data bag,
  # configs/$ENVIRONMENT, or it may be in a chef vault.
  #
  # Try both.
  #
  node.run_state["bcpc_mysql_#{category}_password"] ||=
    (get_config("mysql-#{category}-password") ||
      get_config('password', "mysql-#{category}", 'os'))

  if node.run_state["bcpc_mysql_#{category}_password"].nil?
    raise "Could not find MySQL password for #{category}!"
  end
  
  {
    username: node.run_state["bcpc_mysql_#{category}_username"],
    password: node.run_state["bcpc_mysql_#{category}_password"]
  }
end

#
# Returns a configuration hash suitable for use with mysql2 or the
# database cookbook's providers, using the cluster's global VIP.
#
def mysql_global_vip_connection_info(category='root')
  host_info = {
               host: node[:bcpc][:management][:vip],
               port: 3306
              }
  mysql_local_connection_info.merge(host_info)
end

# all connection info methods should ideally be factored into one
# a task for a sifferent day
# remote is an ip address or a host name
def mysql_remote_connection_info(category='root', remote)
  host_info = {
               host: remote,
               port: 3306
              }
  mysql_local_connection_info.merge(host_info)
end

def wsrep_ready_value(client_options)
  require 'mysql2'
  require 'timeout'

  Timeout.timeout(5) do
    client = Mysql2::Client.new(client_options)
    result = client.query("SHOW GLOBAL STATUS LIKE 'wsrep_ready'")
    result.first['Value']
  end
  rescue
    nil
end
