#
# Cookbook :: bach_ambari
# Recipe :: mysql_server_external_setup
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

mysql_hosts = node['bcpc']['hadoop']['mysql_hosts'].map { |m| m[:hostname] }
node.default['ambari']['databasehost'] = mysql_hosts
mysql_root_password = get_config('mysql-root-password') || get_config('password', 'mysql-root', 'os')
dbhostname = mysql_hosts.map { |m| m.to_s }.first

execute 'execute create ambari database' do
  command "mysql -u root -p#{mysql_root_password} -h #{dbhostname} -e 'CREATE DATABASE IF NOT EXISTS #{node['ambari']['databasename']}'"
  sensitive true
end

execute 'execute grant all PRIVILEGES' do
  command "mysql -u root -p#{mysql_root_password} -h #{dbhostname} -e 'GRANT ALL ON #{node['ambari']['databasename']}.* TO \"#{node['ambari']['databaseusername']}\"@ IDENTIFIED BY \"#{node['ambari']['databasepassword']}\"'"
  sensitive true
end

execute 'execute FLUSH PRIVILEGES' do
  command "mysql -u root -p#{mysql_root_password} -h #{dbhostname} -e 'FLUSH PRIVILEGES'"
  sensitive true
end


mysql_jdbc_url = "jdbc:mysql://"
mysql_port = node['ambari']['databaseport']
hostnameport = node['ambari']['databasehost'].map { |m| m.to_s + ":#{mysql_port}" }.join(",")
mysql_jdbc_url += "#{hostnameport}/#{node['ambari']['databasename']}"

node.default['ambari']['mysql_jdbc_url'] = mysql_jdbc_url

execute 'execute mysql schema script' do
  command "mysql -u #{node['ambari']['databaseusername']} -p#{node['ambari']['databasepassword']} #{node['ambari']['databasename']} -h #{dbhostname} <#{node['ambari']['mysql_schema_path']}"
  sensitive true
  not_if { c = Mixlib::ShellOut.new("mysql -u #{node['ambari']['databaseusername']} -p#{node['ambari']['databasepassword']} #{node['ambari']['databasename']} -h #{dbhostname} --skip-column-names -e 'SELECT count(*) FROM clusters'")
      c.run_command
      c.status.success?
  }
end
