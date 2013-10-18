#
# Cookbook Name:: bcpc
# Recipe:: cobalt
#
# Copyright 2013, Bloomberg L.P.
# Copyright 2013, Gridcentric Inc.
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

if not node["bcpc"]["vms_key"].nil?
    apt_repository "cobalt" do
        uri node['bcpc']['repos']['gridcentric'] % ["cobalt", node['bcpc']['openstack_release']]
        distribution "gridcentric"
        components ["multiverse"]
        key "gridcentric.key"
    end

    apt_repository "cobaltclient" do
        uri node['bcpc']['repos']['gridcentric'] % ["cobaltclient", node['bcpc']['openstack_release']]
        distribution "gridcentric"
        components ["multiverse"]
        key "gridcentric.key"
    end

    apt_repository "vms" do
        uri node['bcpc']['repos']['gridcentric'] % [node['bcpc']['vms_key'], 'vms']
        distribution "gridcentric"
        components ["multiverse"]
        key "gridcentric.key"
    end

    package "cobalt-novaclient" do
        action :upgrade
        options "-o APT::Install-Recommends=0 -o Dpkg::Options::='--force-confnew'"
    end

    template "/etc/nova/cobalt-compute.conf" do
        source "cobalt-compute.conf.erb"
        owner "root"
        group "root"
        mode 00644
    end

    directory "/etc/sysconfig" do
        owner "root"
        group "root"
        mode 00755
    end

    template "/etc/sysconfig/vms" do
        source "vms.erb"
        owner "root"
        group "root"
        mode 00644
    end

    %w{vms vms-apparmor vms-rados vms-libvirt}.each do |pkg|
        package pkg do
            action :upgrade
            options "-o APT::Install-Recommends=0 -o Dpkg::Options::='--force-confnew'"
        end
    end

    %w{cobalt-api cobalt-compute}.each do |pkg|
        package pkg do
            action :upgrade
            options "-o APT::Install-Recommends=0 -o Dpkg::Options::='--force-confnew'"
        end
    end

    service "cobalt-compute" do
        action [ :enable, :start ]
    end

    bash "restart-cobalt" do
        subscribes :run, resources("template[/etc/nova/nova.conf]"), :delayed
        subscribes :run, resources("template[/etc/nova/cobalt-compute.conf]"), :delayed
        subscribes :run, resources("template[/etc/sysconfig/vms]"), :delayed
        notifies :restart, "service[cobalt-compute]", :immediately
    end

    bash "create-vms-disk-pool" do
        user "root"
        code <<-EOH
            ceph osd pool create #{node[:bcpc][:vms_disk_pool]} 1000
            ceph osd pool set #{node[:bcpc][:vms_disk_pool]} size 3
        EOH
        not_if "rados lspools | grep #{node[:bcpc][:vms_disk_pool]}"
    end

    bash "create-vms-mem-pool" do
        user "root"
        code <<-EOH
            ceph osd pool create #{node[:bcpc][:vms_mem_pool]} 1000
            ceph osd pool set #{node[:bcpc][:vms_mem_pool]} size 3
        EOH
        not_if "rados lspools | grep #{node[:bcpc][:vms_mem_pool]}"
    end
end
