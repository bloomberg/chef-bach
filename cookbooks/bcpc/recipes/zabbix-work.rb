#
# Cookbook Name:: bcpc
# Recipe:: zabbix-work
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

include_recipe 'bcpc::default'
include_recipe 'bcpc::zabbix-repo'

# Stop the old service if we find the old service definition
service 'zabbix-agent' do
  action :stop
  only_if { File.exist?('/etc/init/zabbix-agent.conf') }
end

# Remove the old service definition from the source-based build.
file '/etc/init/zabbix-agent.conf' do
  action :delete
end

package 'zabbix-agent'

user node[:bcpc][:zabbix][:user] do
    shell '/bin/false'
    home '/var/log'
    gid node[:bcpc][:zabbix][:group]
    system true
end

directory '/var/log/zabbix' do
    user node[:bcpc][:zabbix][:user]
    group node[:bcpc][:zabbix][:group]
    mode 0755
end

# template '/etc/zabbix/zabbix_agent.conf' do
#     source 'zabbix/zabbix_agent.conf.erb'
#     owner node[:bcpc][:zabbix][:user]
#     group 'root'
#     mode 0600
#     notifies :restart, 'service[zabbix-agent]', :delayed
# end

template '/etc/zabbix/zabbix_agentd.conf' do
    source 'zabbix/agentd.conf.erb'
    owner node[:bcpc][:zabbix][:user]
    group 'root'
    mode 0600
    notifies :restart, 'service[zabbix-agent]', :delayed
end

service 'zabbix-agent' do
    action [:enable, :start]
end

directory '/usr/local/bin/checks' do
  action :create
  owner  node[:bcpc][:zabbix][:user]
  group 'root'
  mode 0775
end 

directory '/usr/local/etc/checks' do
  action  :create
  owner  node[:bcpc][:zabbix][:user]
  group 'root'
  mode 0775
end 
