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

if node['bcpc']['bootstrap']['proxy']
  include_recipe 'bcpc::proxy_configuration'
end

include_recipe 'java'
include_recipe 'java::oracle_jce'
include_recipe 'maven'

# Dependencies of the maven cookbook.
['gyoku', 'nori'].each do |gem_name|
  bcpc_chef_gem gem_name do
    compile_time true
  end
end

#
# On internet-disconnected hosts, node['maven']['repositories'] will
# be overridden with an internal mirror as the first value, and this
# settings resource is extremely important.
#
# On internet-connected hosts, the default value is harmless.
#
maven_settings 'settings.mirrors' do
  value ({
          mirror: {
                   id: 'primary-mirror',
                   name: 'Chef-configured primary mirror',
                   url: node['maven']['repositories'].first,
                   mirrorOf: 'central'
                  }
         })
end

# On internet-connected hosts, maven needs a proxy.
if node['bcpc']['bootstrap']['proxy']
  require 'uri'
  http_uri = URI(node['chef_client']['config']['http_proxy'])
  https_uri = URI(node['chef_client']['config']['https_proxy'])

  maven_settings 'settings.proxies' do
    value({
           proxy: [
                   {
                    id: 'http_proxy',
                    protocol: 'http',
                    active: true,
                    host: http_uri.host,
                    port: http_uri.port,
                    nonProxyHosts: node['chef_client']['config']['no_proxy']
                   },
                   {
                    id: 'https_proxy',
                    protocol: 'https',
                    active: true,
                    host: https_uri.host,
                    port: https_uri.port,
                    nonProxyHosts: node['chef_client']['config']['no_proxy']
                   }
                  ]
          })
  end
end
