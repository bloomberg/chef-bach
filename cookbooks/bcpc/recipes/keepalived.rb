#
# Cookbook Name:: bcpc
# Recipe:: keepalived
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
::Chef::Resource::Template.send(:include, BCPC::Utils)

include_recipe "bcpc::default"

make_config('keepalived-router-id', "#{(rand * 1000).to_i%254/2*2+1}")

keepalived_password = get_config('keepalived-password')
if keepalived_password.nil?
  keepalived_password = secure_password
end

keepalived_admins = (get_head_node_names + [get_bootstrap]).join(',')

chef_vault_secret "keepalived" do
  #
  # For some reason, we are compelled to specify a provider.
  # This will probably break if we ever move to chef-vault cookbook 2.x
  #
  provider ChefVaultCookbook::Provider::ChefVaultSecret

  data_bag 'os'
  raw_data({ 'password' => keepalived_password })
  admins keepalived_admins
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

package "keepalived" do
    action :upgrade
end

template "/etc/keepalived/keepalived.conf" do
    source "#{node[:bcpc][:keepalived][:config_template]}.erb"
    mode 00640
    sensitive true
    notifies :restart, "service[keepalived]", :delayed
    notifies :restart, "service[keepalived]", :immediately
    variables({ node_number: bcpc_8bit_node_number })
end

%w{if_vip if_not_vip vip_change}.each do |script|
    template "/usr/local/bin/#{script}" do
        source "keepalived-#{script}.erb"
        mode 0755
        owner "root"
        group "root"
    end
end

service "keepalived" do
    action [ :enable, :start ]
end

#
# In bcpc::bootstrap, the newest bfd package should have been stuffed
# into the bootstrap's "bins" directory, which is indexed as an apt repo.
#
# In that case, we can set the bfd package source to nil and let apt do
# its job.
#
node.default[:bfd][:package][:source] = nil
include_recipe 'bcpc::cluster_local_repository'
include_recipe 'bfd::default'

if node[:bcpc][:networks].length > 1
  bfd_session "Global Cluster Service VIP Connect" do
    subnet = node[:bcpc][:management][:subnet]
    action :connect
    remote_ip node[:bcpc][:networks][subnet][:management][:gateway]
    local_ip node[:bcpc][:networks][subnet][:management][:vip]
  end
  bfd_session "Global Cluster Service VIP Up" do
    subnet = node[:bcpc][:management][:subnet]
    action :up
    remote_ip node[:bcpc][:networks][subnet][:management][:gateway]
    local_ip node[:bcpc][:networks][subnet][:management][:vip]
  end
else
  service 'bfdd-beacon' do
    action [:stop, :disable]
    ignore_failure true
  end
end
