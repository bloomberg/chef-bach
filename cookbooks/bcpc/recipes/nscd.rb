#
# Cookbook Name:: bcpc
# Recipe:: nscd
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

node.force_default['nscd'].tap do |nscd|
  nscd['databases'] = %w(hosts)

  # Disable non-DNS caching.
  nscd['group']['enable_cache'] = 'no'
  nscd['netgroup']['enable_cache'] = 'no'
  nscd['passwd']['enable_cache'] = 'no'
  nscd['services']['enable_cache'] = 'no'

  # Enable DNS caches.
  nscd['hosts']['enable_cache'] = 'yes'

  # Run the cache daemon as 'nscd'
  nscd['server_user'] = 'nscd'
end

# Create an nscd user and home directory if none exist.
group node['nscd']['server_user'] do
  action :create
  system true
  not_if "getent group #{node['nscd']['server_user']}"
end

user node['nscd']['server_user'] do
  action :create
  group node['nscd']['server_user']
  home '/var/run/nscd'
  system true
  not_if "getent passwd #{node['nscd']['server_user']}"
end

directory '/var/run/nscd' do
  mode 0775
  user 'root'
  group node['nscd']['server_user']
end

include_recipe 'nscd::default'
