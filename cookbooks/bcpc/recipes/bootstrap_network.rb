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

template "/etc/network/interfaces.d/iface-#{node[:bcpc][:bootstrap][:pxe_interface]}.cfg" do
  source "network.iface.erb"
  owner "root"
  group "root"
  mode 00644
  variables(
    :interface => node[:bcpc][:bootstrap][:pxe_interface],
    :ip => node[:bcpc][:bootstrap][:server],
    :netmask => node[:bcpc][:management][:netmask],
    :gateway => node[:bcpc][:management][:gateway],
    :metric => 100
  )
end

service "networking" do
  action :restart
end
