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

%w{make gcc pkg-config libaugeas-dev}.each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

#
# The bfd cookbook, by default, wants to keep the package in the chef
# file cache.
#
# In order to make it easier to deploy bootstraps without internet
# access, here we force bfd to save its package to the 'bins'
# directory and install from same.
#
node.default[:bfd].tap do |bfd|
  bfd[:bin_dir] = node[:bcpc][:bin_dir][:path]

  bfd[:package][:source] =
    ::File.join(node[:bfd][:bin_dir], node[:bfd][:package][:name])
end
include_recipe 'build-essential'
include_recipe 'bfd::install'

require 'pathname'
require 'rubygems'
gem_path = Pathname.new(Gem.ruby).dirname.join('gem').to_s
local_gem_source = 'file:' + node[:bach][:repository][:bins_directory]

bcpc_chef_gem 'ruby-augeas' do
  version '>= 0.0.0'
  compile_time true
end

require 'augeas'

include_recipe "bcpc::default"

bins_dir = '/home/vagrant/chef-bcpc/bins'

include_recipe 'bcpc::chef_vault_download'
include_recipe 'bcpc::chef_vault_install'
include_recipe 'bach_repository::default'

execute 'apt-get update' do
  action :run
end

include_recipe 'bfd::default'

if node[:bcpc][:networks].length > 1
  bfd_session "Global Bootstrap VIP Connect" do
    action :connect
    remote_ip node[:bcpc][:networks][node[:bcpc][:management][:subnet]][:management][:gateway]
    local_ip node[:bcpc][:management][:ip]
  end
  Augeas::open do |aug|
    aug.set("/augeas/load/Interfaces/incl", "/etc/network/interfaces.d/*")
    aug.load
    # Check if an interface file defines the VIP address already -- ifconfig seems a bit loose in its checks
    if aug.match("/files/etc/network/interfaces.d/*/iface/address[. = '#{node[:bcpc][:bootstrap][:vip]}']").length == 0
      ifconfig node[:bcpc][:bootstrap][:vip] do
        device "#{node[:bcpc][:bootstrap][:pxe_interface]}:0"
        mask "255.255.255.255"
        action [:add]
      end
    end
  end
  ifs = node[:network][:interfaces].keys
  # create a hash of ipaddresses -- skip interfaces without addresses
  ips = ifs.map{ |a| node[:network][:interfaces][a].attribute?(:addresses) and
                     node[:network][:interfaces][a][:addresses] or {}}.reduce({}, :merge)
  if not ips.keys.include?(node[:bcpc][:bootstrap][:vip])
    ifconfig node[:bcpc][:bootstrap][:vip] do
      device "#{node[:bcpc][:bootstrap][:pxe_interface]}:0"
      mask "255.255.255.255"
      action [:enable]
    end
  end
  bfd_session "Global Bootstrap VIP Up" do
    action :up
    remote_ip node[:bcpc][:networks][node[:bcpc][:management][:subnet]][:management][:gateway]
    local_ip node[:bcpc][:management][:ip]
  end
else
  service 'bfdd-beacon' do
    action [:stop, :disable]
    ignore_failure true
  end

  # Upstart is not very reliable when stopping bfdd-beacon.
  execute 'killall bfdd-beacon' do
    only_if 'pgrep bfdd'
  end
end

node[:bcpc][:bootstrap][:admin_users].each do |user_name|
  user user_name do
    action :create
    home "/home/#{user_name}"
    group 'vagrant'
    supports :manage_home => true
  end
  bash 'set group permission on homedir' do
    code "chmod 775 /home/#{user_name}"
  end
end

sudo 'cluster-interaction' do
  user      node[:bcpc][:bootstrap][:admin_users] * ','
  runas     'vagrant'
  commands  ['/home/vagrant/chef-bcpc/cluster-assign-roles.sh','/home/vagrant/chef-bcpc/nodessh.sh','/usr/bin/knife']
  only_if { node[:bcpc][:bootstrap][:admin_users].length >= 1 }
end

package 'acl'

cron 'synchronize chef' do
  user  'vagrant'
  home '/home/vagrant'
  command 'cd ~/chef-bcpc; ' \
    'knife role from file roles/*.json; ' \
    'knife cookbook upload -a; '\
    "knife environment from file environments/#{node.chef_environment}.json"
end

package 'sshpass'

include_recipe 'bcpc::chef_client'
