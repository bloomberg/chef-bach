#
# Cookbook Name:: webhdfs
# Recipe:: test_hdfs_directory
#
# Copyright 2015, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,software
# distributed under the License is distributed on an "AS IS"BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Recipe for chefspec test case of hdfs_directory_spec.rb

webhdfs_hdfs_directory '/tmp/only_with_owner' do
  owner 'hdfs'
  user 'tony'
  hosts 'host:14000'
  action :create
end

webhdfs_hdfs_directory '/tmp/only_with_group' do
  group 'hdfs'
  user 'tony'
  hosts 'host:14000'
  action :create
end

webhdfs_hdfs_directory '/tmp/with_group_owner' do
  user 'tony'
  owner 'guest'
  hosts 'host:14000'
  group 'supergroup'
  action :create
end 

webhdfs_hdfs_directory '/user/tony/with_delete' do
  user 'tony'
  hosts 'host:14000'
  recursive true
  action :delete
end

webhdfs_hdfs_directory '/tmp/with_mode' do
  user 'tony'
  owner 'guest'
  hosts 'host:14000'
  mode "650"
  action :create
end
