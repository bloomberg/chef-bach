#
# Cookbook :: bach_ambari
# Attributes :: default
# Copyright 2018, Bloomberg Finance L.P.
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

node.force_default['ambari']['install_java'] = false
node.force_default['ambari']['java_home'] = "#{node['bcpc']['hadoop']['java']}"


# Ambari External Database attributes
node.force_default['ambari']['db_type'] = 'mysql'

mysql_port = node['bcpc']['hadoop']['mysql_port'] || 3306

node.force_default['ambari']['databaseport'] = "#{mysql_port}"
# node.force_default['ambari']['databasehost'] = mysql_hosts
node.force_default['ambari']['databasename'] = 'ambari'
node.force_default['ambari']['databaseusername'] = 'ambari'
node.force_default['ambari']['databasepassword'] = get_config('mysql-ambari-password') || get_config('password', 'mysql-ambari', 'os')
node.default['ambari']['mysql_schema_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql'
