#
# Cookbook Name:: bcpc
# Recipe:: diamond
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

execute 'apt-get update' do
  action :run
end

%w{python-support python-configobj python-pip python-httplib2}.each do |pkg|
    package pkg do
        action :upgrade
    end
end

package "diamond" do
    action :install
end

if node[:bcpc][:virt_type] == "kvm"
    package "ipmitool" do
        action :upgrade
    end
    package "smartmontools" do
        action :upgrade
    end
end

python_pip "pyrabbit" do
    options "--index #{get_binary_server_url}/python/simple"
    action :install
end

bash "diamond-set-user" do
    user "root"
    self.code <<-EOM
        sed --in-place '/^DIAMOND_USER=/d' /etc/default/diamond
        echo 'DIAMOND_USER="root"' >> /etc/default/diamond
    EOM
    not_if "grep -e '^DIAMOND_USER=\"root\"' /etc/default/diamond"
    notifies :restart, "service[diamond]", :delayed
end

has_mysql = get_nodes_for("mysql","bcpc").include?(node)

template "/etc/diamond/diamond.conf" do
    source "diamond.conf.erb"
    owner "diamond"
    group "root"
    mode 00600
    variables( :servers => get_head_nodes, :has_mysql => has_mysql )
    notifies :restart, "service[diamond]", :delayed
end

service "diamond" do
    action [ :enable, :start ]
end
