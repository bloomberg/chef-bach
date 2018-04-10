#
# Cookbook Name:: bcpc-hadoop
# Recipe:: maven_config
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

maven_file = Pathname.new(node['maven']['url']).basename

# Dependencies of the maven cookbook.
%w(gyoku nori).each do |gem_name|
  bcpc_chef_gem gem_name do
    compile_time true
  end
end

include_recipe 'bcpc-hadoop::ssl_configuration'
include_recipe 'bcpc::proxy_configuration'
include_recipe 'maven::default'

keystore_path = node['bcpc']['hadoop']['java_ssl']['keystore']
keystore_password = node['bcpc']['hadoop']['java_ssl']['password']

node.override['maven']['mavenrc']['opts'] =
    "#{node['maven']['mavenrc']['opts']} " \
    "-Djavax.net.ssl.trustStore=#{keystore_path} " \
    "-Djavax.net.ssl.trustStorePassword=#{keystore_password} "

# Setup custom maven config
directory '/root/.m2' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

include_recipe 'maven::settings'

unless node['bcpc']['bootstrap']['proxy'].nil?
  maven_settings 'settings.proxies' do
    uri = URI(node['bcpc']['bootstrap']['proxy'])
    value proxy: {
      active: true,
      protocol: uri.scheme,
      host: uri.host,
      port: uri.port,
      nonProxyHosts: node['bcpc']['no_proxy'].join('|')
    }
  end
end

# it looks like the Maven cookbook uses the default
# restrictive umask from Chef-Client
execute 'chmod maven' do
  command "chmod -R 755 #{node['maven']['m2_home']}"
end
