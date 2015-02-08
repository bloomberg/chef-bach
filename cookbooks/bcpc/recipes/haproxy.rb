Chef::Resource.send(:include, Bcpc::OSHelper)
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

Bcpc::OSHelper.set_config(node, 'haproxy-stats-user', "haproxy")
Bcpc::OSHelper.set_config(node, 'haproxy-stats-password', Bcpc::Helper.secure_password)

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

template "/etc/haproxy/haproxy.cfg" do
    source "haproxy.cfg.erb"
    mode 00644
    helpers(Bcpc::OSHelper)
	variables( :nova_servers => Bcpc::OSHelper.get_nodes_for("nova-work",node,"bcpc"),
                   :mysql_servers => Bcpc::OSHelper.get_nodes_for("mysql",node,"bcpc"),
                   :rabbitmq_servers => Bcpc::OSHelper.get_nodes_for("rabbitmq",node,"bcpc"),
                   :ldap_servers => Bcpc::OSHelper.get_nodes_for("389ds",node,"bcpc"),
                   :keystone_servers => Bcpc::OSHelper.get_nodes_for("keystone",node,"bcpc"),
                   :glance_servers => Bcpc::OSHelper.get_nodes_for("glance",node,"bcpc"),
                   :cinder_servers => Bcpc::OSHelper.get_nodes_for("cinder",node,"bcpc"),
                   :horizon_servers => Bcpc::OSHelper.get_nodes_for("horizon",node,"bcpc"),
                   :elasticsearch_servers => Bcpc::OSHelper.get_nodes_for("elasticsearch",node,"bcpc"),
                   :radosgw_servers => Bcpc::OSHelper.get_nodes_for("ceph-rgw",node,"bcpc"))
	notifies :restart, "service[haproxy]", :immediately
end

service "haproxy" do
    restart_command "service haproxy stop && service haproxy start && sleep 5"
    action [ :enable, :start ]
end
