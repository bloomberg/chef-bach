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

gem_package 'ruby-augeas' do
    gem_binary gem_path
    version ">=0.0.0"
    action :nothing
end.run_action(:install)

#
# With a restrictive umask chef installs gemspec files with permission 770 on bootstrap node 
# Need to change it so that all the users can read it without which knife without sudo will fail
#
Gem.path.each do |dir|
  Dir[Pathname.new(dir).join("specifications","ruby-augeas*")].each do |val|
    file "#{val}" do
      action :create
      mode "0644"
    end
  end
end

Gem.clear_paths
require 'augeas'

include_recipe "bcpc::default"

bins_dir = '/home/vagrant/chef-bcpc/bins'

directory bins_dir do
  action :create
  mode 0755
  recursive true
end

#
# If we have valid vault items for the public and private key, write
# files based on the vault items.
#
# If we don't have valid vault items, generate the files by calling
# build_bins.sh, then create vault items based on the files.
#
include_recipe 'bcpc::chef_vault_download'
include_recipe 'bcpc::chef_vault_install'
require 'base64'

gpg_private_key_path = ::File.join('/home/vagrant', 'apt_key.sec')
gpg_public_key_path = ::File.join(bins_dir, 'apt_key.pub')

gpg_private_key_base64 = get_config('bootstrap-gpg-private_key_base64')
gpg_public_key_base64 = get_config('bootstrap-gpg-public_key_base64')

if gpg_private_key_base64 && gpg_public_key_base64
  file gpg_private_key_path do
    mode 0400
    content Base64.decode64(gpg_private_key_base64)
  end

  file gpg_public_key_path do
    mode 0444
    content Base64.decode64(gpg_public_key_base64)
  end
else
  log 'Running build bins to generate GPG keys' do
    notifies :run, 'bash[build_bins]', :immediately
  end

  #
  # The GPG public key is stored in the unencrypted "configs" data bag, so
  # nodes can retrieve it without chef vault.
  #
  ruby_block 'make_data_bag' do
    block do
    make_config('bootstrap-gpg-public_key_base64',
                 Base64.encode64(::File.read(gpg_public_key_path)))
    end
  end

  chef_vault_secret 'bootstrap-gpg' do
    data_bag 'os'
    raw_data lazy {
      {
       private_key_base64: Base64.encode64(::File.read(gpg_private_key_path)),
      }
    }
    admins [node[:fqdn]]
    search '*:*'
    action :nothing
  end
end

#
# Re-run build_bins if any of the index files is older than the files
# being indexed.
#
# This can happen when other recipes edit the bins directory, but don't
# run build_bins.sh themselves. (e.g. bfd::install)
#
bash 'build_bins' do
  user 'root'
  cwd '/home/vagrant/chef-bcpc'
  code './build_bins.sh'
  umask 0002
  action :run
  only_if {
    
    apt_index = ::File.join(bins_dir, 'dists/0.5.0/main/binary-amd64/Packages')
    apt_glob = ::Dir.glob(::File.join(bins_dir, '*.deb'))

    gem_index = ::File.join(bins_dir, 'latest_specs.4.8')
    gem_glob = ::Dir.glob(::File.join(bins_dir,'gems/*.gem'))

    gpg_index = ::File.join(bins_dir, 'apt_key.asc')
    gpg_glob = ::Dir.glob(gpg_public_key_path)

    [
      [apt_index, apt_glob],
      [gem_index, gem_glob],
      [gpg_index, gpg_glob],
    ].map do |index, glob|
      begin
        ::File.mtime(apt_index) < glob.map{ |pp| ::File.mtime(pp) }.max
      rescue
        nil
      end
    end.any? || Dir.glob(::File.join(bins_dir, '*.gem')).any?
  }
end

# Do a complete apt-get update just in case build_bins updated the local repo.
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
  end

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

link '/etc/chef/client.d/knife.rb' do
  to '/home/vagrant/chef-bcpc/.chef/knife.rb'
end
