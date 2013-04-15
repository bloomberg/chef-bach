#
# Cookbook Name:: bcpc
# Recipe:: kibana
#
# Copyright 2013, Bloomberg L.P.
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

package "rubygems" do
    action :upgrade
end

cookbook_file "/tmp/kibana.tgz" do
    source "bins/kibana.tgz"
    owner "root"
    mode 00444
end

user node[:bcpc][:kibana][:user] do
    shell "/bin/false"
    home "/var/log"
    gid node[:bcpc][:kibana][:group]
    system true
end

bash "install-kibana" do
    code <<-EOH
        tar zxf /tmp/kibana.tgz -C /opt/
    EOH
    not_if "test -d /opt/kibana"
end

directory "/var/log/kibana" do
    user node[:bcpc][:kibana][:user]
    group node[:bcpc][:kibana][:group]
    mode 00755
end

template "/etc/init/kibana.conf" do
    source "upstart-kibana.conf.erb"
    user node[:bcpc][:kibana][:user]
    group node[:bcpc][:kibana][:group]
    mode 00644
    notifies :restart, "service[kibana]", :delayed
end

template "/opt/kibana/KibanaConfig.rb" do
    source "kibana.rb.erb"
    user node[:bcpc][:kibana][:user]
    group node[:bcpc][:kibana][:group]
    mode 00644
    notifies :restart, "service[kibana]", :delayed
end

service "kibana" do
    provider Chef::Provider::Service::Upstart
    action [ :enable, :start ]
end
