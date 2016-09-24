#
# Cookbook Name:: webhdfs
# Recipe:: test_webhdfs_file
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
# run as: chef-client --local-mode --runlist "recipe[webhdfs::test_webhdfs_file]"

# replace the following "<>" with real value 
uname = '' # '***'
alien = '' # '***'
file = '' # '***'
url = '' # '***'

# regular test
Chef::Log.info "Regular File operation testing for create, touch, and delete"
webhdfs_hdfs_file file do
  # provider Chef::Provider::HdfsDir
  path file
  user uname
  hosts url
  owner uname
  action :create
end

webhdfs_hdfs_file file do
  #provider Chef::Provider::HdfsDir
  user uname
  hosts url
  owner uname
  action :create_if_missing
  group 'supergroup'
end

webhdfs_hdfs_file file do
  #provider Chef::Provider::HdfsDir
  user uname
  hosts url
  action :touch
end

webhdfs_hdfs_file file do
  #provider Chef::Provider::HdfsDir
  user uname
  hosts url
  action :delete
end

# irregluar test
## wrong user to talk to HDFS
Chef::Log.info "Wrong File operation testing - no-auth user talk to HDFS"
webhdfs_hdfs_file file do 
  path file
  user 'guest'
  hosts url
  owner uname
  action :create
end

webhdfs_hdfs_file file do
  path file
  user uname
  hosts url
  action :delete
end

## set ownership of a file to different user
Chef::Log.info "Wrong File operation testing - no-owner user operate on the other's file"
webhdfs_hdfs_file file do
  user alien # uname, none
  hosts url
  owner alien
  action :create
end
webhdfs_hdfs_file file do
  user uname
  hosts url
  action :delete
end

## delete a file not belongs to a user
Chef::Log.info "Wrong File operation testing - delete the other's file"
webhdfs_hdfs_file file do
  hosts url
  user uname
  owner uname
  action :create
end
webhdfs_hdfs_file file do
  user alien
  hosts url
  action :delete
end
webhdfs_hdfs_file file do
  user uname
  hosts url
  action :delete
end

## delete a non-existed file
Chef::Log.info "Wrong File operation testing - delete a non-existed file"
webhdfs_hdfs_file file do
  user uname
  hosts url
  action :delete
end

