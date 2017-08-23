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

include_recipe 'java'
include_recipe 'java::oracle_jce'
include_recipe 'maven'

# Implicit dependencies of the maven cookbook.
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
                   mirrorOf: '*'
                  }
         })
end
