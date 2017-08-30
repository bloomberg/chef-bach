#
# Cookbook Name:: bcpc-hadoop
# Recipe: mysql_connector
#
# Copyright 2017, Bloomberg Finance L.P.
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
# This recipe installs the MySQL connector for java to /usr/share/java.
#
include_recipe 'bcpc-hadoop::maven_config'

# On Ubuntu hosts, remove the old debian package.
if node[:platform_family] == 'debian'
  apt_package 'mysql-connector-java' do
    action :purge
  end
end

directory '/usr/share/java' do
  mode 0555
  user 'root'
  group 'root'
  recursive true
  action :create
end

maven 'mysql-connector-java' do
  group_id 'mysql'
  version  '5.1.43'
  dest '/usr/share/java/mysql-connector-java.jar'
  action :put
  timeout 1800
end

link '/usr/share/java/jdbc-mysql.jar' do
  to '/usr/share/java/mysql-connector-java.jar'
end
