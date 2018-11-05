#
# Cookbook Name:: bach_repository
# Recipe:: jvmkill
#
# Copyright 2013, Bloomberg Finance L.P.
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
# This recipe will download and compile jvmkill library
# and save the libjvmkill.so in the bins directory

require 'tmpdir'

include_recipe 'bach_repository::directory'

bins_dir = node['bach']['repository']['bins_directory']
src_dir = node['bach']['repository']['src_directory']
build_dir = src_dir + '/jvmkill'
lib_file = build_dir + '/libjvmkill.so'
target_file = bins_dir + '/libjvmkill.so'

# checkout
git build_dir do
  repository 'https://github.com/airlift/jvmkill.git'
  action :sync
  not_if { File.exist?target_file }
end

# compile
execute 'jvmkill-make' do
  command "make JAVA_HOME=#{node['bcpc']['hadoop']['java']}"
  cwd build_dir
  not_if { File.exist?(target_file) }
end

# deploy
remote_file target_file do
  source "file://#{lib_file}"
  mode 0o0444
  not_if { File.exist?(target_file) }
end
