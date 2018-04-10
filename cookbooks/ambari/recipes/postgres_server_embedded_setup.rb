#
# Cookbook :: ambari
# Recipe :: postgres_server_embedded_setup 
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


# Ambari local database attributes
node.default['postgresql']['assign_postgres_password'] = false
node.default['postgresql']['server']['config_change_notify'] = :reload

# installing postgresql client and server
include_recipe 'postgresql'
include_recipe 'postgresql::server'

# create ambari user and database
execute 'excute embedded postgres script' do
  command "su - postgres --command=\"psql -f #{node['ambari']['pg_db_script_path']} -v username=#{node['ambari']['databaseusername']} -v password=\\\'\'#{node['ambari']['databasepassword']}\'\\\' -v dbname=#{node['ambari']['databasename']}\""
end

# preparing ambari database schema
execute 'excute postgres schema script' do
  command "psql -h localhost -f #{node['ambari']['pg_schema_path']} -U \'#{node['ambari']['databaseusername']}\' -d \'#{node['ambari']['databasename']}\'"
  environment ({'PGPASSWORD' => "#{node['ambari']['databasepassword']}"})
end
