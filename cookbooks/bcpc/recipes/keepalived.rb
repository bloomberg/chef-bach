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

include_recipe "bcpc::default"

make_bcpc_config('keepalived-router-id', "#{(rand * 1000).to_i%254/2*2+1}")

keepalived_password = get_bcpc_config('keepalived-password')
if keepalived_password.nil?
  keepalived_password = secure_password
end

bootstrap = get_bootstrap
results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results

chef_vault_secret "keepalived" do
  data_bag 'os'
  raw_data({ 'password' => keepalived_password })
  admins "#{ nodes },#{ bootstrap }"
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
