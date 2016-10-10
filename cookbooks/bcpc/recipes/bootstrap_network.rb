#
# Cookbook Name:: bcpc
# Recipe:: bootstrap
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

package 'sshpass'

directory "/etc/network/interfaces.d" do
  action :create
  owner 'root'
  group 'root'
  mode '0755'
end

template "/etc/network/interfaces" do
  source "network.interfaces.erb"
  owner "root"
  group "root"
  mode 00644
end

#
# We assume that the bootstrap pxe interface will allow us to identify
# the correct subnet definition in the environment.
#
require 'ipaddress'
bootstrap_ip = IPAddress(node[:bcpc][:bootstrap][:server])
#
# The keys of the hash are subnet names, so we at the end, we grab '.keys.first'
# The values are only useful in choosing which key to grab.
#
rack_name = node[:bcpc][:networks].select do |_, networks|
  mgmt_subnet = networks[:management]
  network_ip = IPAddress(mgmt_subnet[:gateway] + '/' + mgmt_subnet[:netmask])
  bootstrap_ip.netmask = mgmt_subnet[:netmask]
  network_ip.network == bootstrap_ip.network
end.keys.first

mgmt_subnet = node[:bcpc][:networks][rack_name][:management]

template "/etc/network/interfaces.d/iface-#{node[:bcpc][:bootstrap][:pxe_interface]}.cfg" do
  source "network.iface.erb"
  owner "root"
  group "root"
  mode 00644
  variables(
    :interface => node[:bcpc][:bootstrap][:pxe_interface],
    :ip => node[:bcpc][:bootstrap][:server],
    :netmask => mgmt_subnet[:netmask],
    :gateway => mgmt_subnet[:gateway],
    :metric => 100
  )
end

replace_or_add 'disable DHCP router overwriting' do
  router = mgmt_subnet['gateway']
  path '/etc/dhcp/dhclient.conf'
  pattern 'supersede routers'
  line "supersede routers #{router};"
end

execute 'interfaces up' do
  command 'ifup -a'
end

['eth0','eth1'].each do |iface|
  execute "restart #{iface}" do
    command "ifdown #{iface}; ifup #{iface}"
  end
end
