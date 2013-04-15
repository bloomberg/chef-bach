#
# Cookbook Name:: bcpc
# Recipe:: elasticsearch
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

package "openjdk-7-jre-headless" do
    action :upgrade
end

cookbook_file "/tmp/elasticsearch-0.20.2.deb" do
    source "bins/elasticsearch-0.20.2.deb"
    owner "root"
    mode 00444
end

package "elasticsearch" do
    provider Chef::Provider::Package::Dpkg
    source "/tmp/elasticsearch-0.20.2.deb"
    action :install
end

service "elasticsearch" do
    action [ :enable, :start ]
end

template "/etc/elasticsearch/elasticsearch.yml" do
    source "elasticsearch.yml.erb"
    owner "root"
    group "root"
    mode 00644
    variables( :servers => get_head_nodes )
    notifies :restart, "service[elasticsearch]", :immediately
end

directory "/usr/share/elasticsearch/plugins" do
    owner "root"
    group "root"
    mode 00755
end

cookbook_file "/tmp/elasticsearch-plugins.tgz" do
    source "bins/elasticsearch-plugins.tgz"
    owner "root"
    mode 00444
end

bash "install-elasticsearch-plugins" do
    code <<-EOH
        tar zxf /tmp/elasticsearch-plugins.tgz -C /usr/share/elasticsearch/plugins/
    EOH
    not_if "test -d /usr/share/elasticsearch/plugins/head"
end
