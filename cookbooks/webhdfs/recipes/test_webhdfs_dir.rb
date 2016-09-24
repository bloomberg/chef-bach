#
# Cookbook Name:: webhdfs
# Recipe:: test_webhdfs_dir
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
# run as: chef-client --local-mode --runlist "recipe[webhdfs::test_webhdfs_dir]"

# replace the following "<>" with real value
uname = '' # <userID> # '***'
alien = '' # <alien user ID> # '***'
dir = '' # '***'
url = '' # <endpoint host URL or IP> # '***'

# regular test
Chef::Log.info "Regular File operation testing - create a dir with owner and group info"
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  owner uname
  group 'supergroup'
  action :create
end

webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  action :delete
end


Chef::Log.info "Regular File operation testing - recursive delete a nested dir"
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  owner uname
  action :create
end

webhdfs_hdfs_directory "#{ dir }/tmp" do
  # provider Chef::Provider::HdfsDir
  user uname
  hosts url
  owner uname
  action :create
end

webhdfs_hdfs_directory "#{ dir }/tmp" do
  # provider Chef::Provider::HdfsDir
  user uname
  hosts url
  recursive true
  action :delete
end

# irregular test
## wrong user to talk to HDFS
Chef::Log.info "Wrong File operation testing - non-auth user talk to HDFS"
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user 'guest'
  hosts url
  owner uname
  action :create
end
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  action :delete
end

## set ownership of a directory to different user
Chef::Log.info "Wrong File operation testing - set ownership of a directory to different user"
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user alien
  hosts url
  owner alien
  action :create
end
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  action :delete
end

## delete a directory not belongs to a user
Chef::Log.info "Wrong File operation testing - delete a directory not belongs to a user"
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  hosts url
  user uname
  owner uname
  action :create
end
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user alien
  hosts url
  action :delete
end
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  action :delete
end

## delete a non-existed directory
Chef::Log.info "Wrong File operation testing - delete a non-existed directory"
webhdfs_hdfs_directory dir do
  # provider Chef::Provider::HdfsDir
  path dir
  user uname
  hosts url
  action :delete
end

webhdfs_hdfs_directory '/tmp/connection_failed' do
  # provider Chef::Provider::HdfsDir
  user uname
  hosts ''
  action :delete
end

