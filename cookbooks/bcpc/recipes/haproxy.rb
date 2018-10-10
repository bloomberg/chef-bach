#
# Cookbook Name:: bcpc
# Recipe:: haproxy
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

make_config('haproxy-stats-user', "haproxy")

# backward compatibility
haproxy_stats_password = get_config("haproxy-stats-password")
if haproxy_stats_password.nil?
  haproxy_stats_password = secure_password
end

haproxy_admins = (get_head_node_names + [get_bootstrap] + ['admin']).join(',')

chef_vault_secret "haproxy-stats" do
  data_bag 'os'
  raw_data({ 'password' => haproxy_stats_password })
  admins haproxy_admins
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

package "haproxy" do
    action :upgrade
end

bash "enable-defaults-haproxy" do
  user "root"
  code <<-EOH
    sed --in-place '/^ENABLED=/d' /etc/default/haproxy
    echo 'ENABLED=1' >> /etc/default/haproxy
  EOH
  not_if "grep -e '^ENABLED=1' /etc/default/haproxy"
end

# FIXME: use the servers_recipe and servers_cookbook to find the servers on which the backend service
#        should be running. This should be replaced by static parse of cluster.txt in the attribute file
#        and passed to here directly via 'servers'
modified_ha_services = node['bcpc']['haproxy']['ha_services'].map{ |service|
  service.merge({
    'servers' => get_nodes_for_multi(service['servers_recipes_in_cookbooks']).map { |hst|
      {
        'fqdn' => hst['fqdn'],
        'floating_fqdn' => float_host(hst['fqdn']),
        'floating_ip' => hst['bcpc']['floating']['ip'],
        'port' => service['servers_port']
      }
    }
  })
}

mysql_servers = get_nodes_for("mysql","bcpc").collect { |hst|
  {
    'fqdn' => hst['fqdn'],
    'ip' => hst['bcpc']['management']['ip']
  }
}

template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
  mode 00644
  variables(:mysql_servers => mysql_servers,
            :floating_vip => node['bcpc']['floating']['vip'],
            :management_vip => node['bcpc']['management']['vip'],
            :local_management_ip => node['bcpc']['management']['ip'],
            :local_floating_ip => node['bcpc']['floating']['ip'],
            :haproxy_stats_user => get_config('haproxy-stats-user'),
            :haproxy_stats_pwd => get_config!('password',"haproxy-stats","os"),
            :haproxy_tune_chksize => node['bcpc']['haproxy']['tune_chksize'],
            :ha_services => modified_ha_services
           )
  notifies :restart, "service[haproxy]", :immediately
end

service "haproxy" do
  restart_command "service haproxy stop && service haproxy start && sleep 5"
  action [ :enable, :start ]
end
