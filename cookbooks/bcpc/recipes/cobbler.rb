#
# Cookbook Name:: bcpc
# Recipe:: cobbler
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

require 'digest/sha2'
require 'chef-vault'

make_bcpc_config('cobbler-web-user', "cobbler")

create_databag("os")

# backward compatibility
web_passwd = get_bcpc_config('cobbler-web-password')
if web_passwd.nil?
  web_passwd = secure_password
end
root_passwd = get_bcpc_config('cobbler-root-password')
if root_passwd.nil?
  root_passwd = secure_password
end

# #
# # This does not currently work.
# #
# # Cobbler secrets are currently pre-created by chef-provisioning
# # recipes to work around a Chef server issue.
# #
# chef_vault_secret "cobbler" do
#   data_bag 'os'
#   raw_data({ 'web-password' => web_passwd, 'root-password' => root_passwd, 'root-password-salted' => root_passwd.crypt("$6$" + rand(36**8).to_s(36)) })
#   admins [Chef::Config[:node_name], node['bach']['cluster']['user']['name']]
#   search '*:*'
#   action :nothing
# end.run_action(:create_if_missing)

node.default[:cobbler][:web_username] = get_bcpc_config('cobbler-web-user')
node.default[:cobbler][:web_password] = get_bcpc_config( 'web-password', 'cobbler', 'os')

package "isc-dhcp-server"

include_recipe 'cobblerd'
include_recipe "cobblerd::web"

template "/etc/cobbler/settings" do
    source "cobbler.settings.erb"
    mode 00644
    notifies :restart, "service[cobbler]", :delayed
end

template "/etc/cobbler/dhcp.template" do
    source "cobbler.dhcp.template.erb"
    mode 00644
    variables( :range => node[:bcpc][:bootstrap][:dhcp_range],
               :subnet => node[:bcpc][:bootstrap][:dhcp_subnet] )
    notifies :restart, "service[cobbler]", :delayed
end

cobbler_image 'ubuntu-12.04-mini' do
  source "#{get_binary_server_url}/ubuntu-12.04-mini.iso"
  os_version 'precise'
  os_breed 'ubuntu'
  action :import
end

cobbler_profile "bcpc_host" do
  kickstart "cobbler.bcpc_ubuntu_host.preseed"
  distro "ubuntu-12.04-mini-x86_64"
  action :import
end

service "isc-dhcp-server" do
    action [ :enable, :start ]
end
