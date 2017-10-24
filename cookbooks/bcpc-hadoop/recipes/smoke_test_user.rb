# vim: tabstop=2:shiftwidth=2:softtabstop=2 
#
# Cookbook Name:: bcpc-hadoop
# Recipe:: smoke_test_user
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

test_user = node['hadoop_smoke_tests']['oozie_user']

# create a local user and group if needed
user test_user do
  manage_home true
  comment 'hadoop smoke test executer'
  only_if {node['hadoop_smoke_tests']['create_local_user'] == true}
end

group test_user do 
  only_if {node['hadoop_smoke_tests']['create_local_group'] == true}
end

# create hdfs home
execute 'hdfs home for smoke test executer' do
  command "hdfs dfs -mkdir -p /user/#{test_user}"
  user 'hdfs'
  only_if {node['hadoop_smoke_tests']['create_local_user'] == true}
end

execute 'chown home for smoke test executer' do
  command "hdfs dfs -chown #{test_user} /user/#{test_user}"
  user 'hdfs'
  only_if {node['hadoop_smoke_tests']['create_local_user'] == true}
end

