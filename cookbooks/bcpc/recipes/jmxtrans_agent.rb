#
# Cookbook Name:: bcpc
# Recipe:: jmxtrans_agent
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
# This recipe deploys the jmxtrans-agent.jar to the following location
#
require 'pathname'

lib_file = node['bcpc']['jmxtrans_agent']['lib_file']
lib_file_name = Pathname.new(lib_file).basename.to_s
lib_file_path = Pathname.new(lib_file).dirname.to_s
src_file_url = File.join(get_binary_server_url, lib_file_name)

directory lib_file_path do
  owner 'ubuntu'
  group 'ubuntu'
  mode '0755'
  recursive true
end

remote_file lib_file.to_s do
  source src_file_url
  owner 'ubuntu'
  group 'ubuntu'
  mode '0755'
end
