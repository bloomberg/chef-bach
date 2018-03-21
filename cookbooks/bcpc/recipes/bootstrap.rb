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

require 'socket'
puts node['bcpc']['bootstrap']['vip']
bootstrap_vip_ip = IPSocket.getaddress(node['bcpc']['bootstrap']['vip'])

user = node['bcpc']['bootstrap']['admin']['user']
node.default['bcpc']['bootstrap']['is_bootstrap'] = true

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

bins_dir = "/home/#{user}/chef-bcpc/bins"

include_recipe 'bcpc::chef_vault_download'
include_recipe 'bcpc::chef_vault_install'
include_recipe 'bach_repository::default'

execute 'apt-get update' do
  action :run
end
if node[:bcpc][:management][:ip] != node[:bcpc][:management][:vip]
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
    if aug.match("/files/etc/network/interfaces.d/*/iface/address[. = '#{bootstrap_vip_ip}']").length == 0
      ifconfig bootstrap_vip_ip do
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
  if not ips.keys.include?(bootstrap_vip_ip)
    ifconfig bootstrap_vip_ip do
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
end

#
# Admin users have not been (intentionally) active on BACH bootstraps
# in several years.  Delete them if found.
#
node[:bcpc][:bootstrap][:admin_users].each do |user_name|
  user user_name do
    action :remove
    only_if "id #{user_name}"
    ignore_failure true
  end
end

package 'acl'

cron 'synchronize chef' do
  user  "#{user}"
  home "/home/#{user}"
  command 'cd ~/chef-bcpc; ' \
    'knife role from file roles/*.json; ' \
    'knife cookbook upload -a; '\
    "knife environment from file environments/#{node.chef_environment}.json"
end

package 'sshpass'

include_recipe 'bcpc::chef_client'

cron 'restart-chefserver' do
  command '/usr/bin/chef-server-ctl restart'
  day '1'
  hour '10'
  weekday '1'
end
