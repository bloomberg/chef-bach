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
  node.run_state["bcpc_mysql_#{category}_username"] ||=
    get_config!("mysql-#{category}-user")

  node.run_state["bcpc_mysql_#{category}_password"] ||=
    get_config!('password', "mysql-#{category}", 'os')
  
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
