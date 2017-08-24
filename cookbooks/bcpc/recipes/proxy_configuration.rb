#
# Cookbook Name:: bcpc
# Recipe:: proxy_configuration
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
# The BACH proxy configuration is generated for the chef_client, but
# it is not normally added to the environment for use by child
# processes.
#
# This recipe exists to edit the environment.
#
if node['bcpc']['bootstrap']['proxy']
  log('Configuring proxy environment variables')

  ruby_block 'configure-proxy' do
    block do
      ENV['http_proxy'] ||= node['chef_client']['config']['http_proxy']
      ENV['https_proxy'] ||= node['chef_client']['config']['https_proxy']
      ENV['no_proxy'] ||= node['chef_client']['config']['no_proxy']
    end
  end
end
