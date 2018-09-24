#
# Cookbook Name:: bcpc
# Recipe:: ssh
#
# Copyright 2017, Bloomberg Finance L.P.
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

#
# This recipe saves a host's SSH keys to a chef-vault encrypted data
# bag, so that they can be persisted across OS installations.
#
# It has to be done in a data bag because we commonly delete the node
# and client objects when a host is reinstalled.
#

include_recipe 'bcpc::chef_gems'

package 'openssh-client' do
  action :upgrade
end

package 'openssh-server' do
  action :upgrade
end

service 'ssh' do
  action [:enable, :start]
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode 00644
  variables lazy { {
    address_family: node['bcpc']['ssh']['address_family'],
    listen_address: node[:bcpc][:management][:ip],
    x11_forwarding: (node['bcpc']['ssh']['x11_forwarding'] ? 'yes' : 'no')
  } }

  # Don't rewrite the file unless we know the listen address is valid!
  notifies :reload, 'service[ssh]'
  only_if {
    bound_addresses = node[:network][:interfaces]
      .map { |_, ii| ii[:addresses] }
      .reduce({}, :merge)
      .select{ |_, data| data[:family].include?('inet') }.keys

    bound_addresses.include?(node[:bcpc][:management][:ip])
  }
end

require 'chef-vault'

def load_ssh_keys
  ChefVault::Item.load('ssh_host_keys', node[:fqdn])
rescue Exception => ee
  Chef::Log.warn("Failed to load ssh_host_keys/#{node[:fqdn]}:\n#{ee}")
  return nil
end

def create_ssh_keys
  vault_item = ChefVault::Item.new('ssh_host_keys', node[:fqdn])
  vault_item.admins([get_bootstrap, node[:fqdn], 'admin'].join(','))
  vault_item.search("fqdn:#{node[:fqdn]}")
  vault_item.save
rescue Exception => eee
  Chef::Log.warn("Failed to create new vault ssh_host_keys/#{node[:fqdn]}")
  Chef::Log.warn("Is this node an admin?\n#{eee}")
  return nil
end

if node[:fqdn] != get_bootstrap
  # First, try to retrieve existing host keys from the vault.
  # If we fail to load from the vault, log the failure and create an item.
  # If we also fail to create a vault item, this node may not be an admin.
  vault_item = load_ssh_keys || create_ssh_keys
  if vault_item.nil?
    raise 'Failed to load / create vault item for ssh_host_keys'
  end

  ssh_key_types = %w(dsa ecdsa ed25519 rsa)
  ssh_key_types.each do |key_type|
    private_key_path = "/etc/ssh/ssh_host_#{key_type}_key"
    public_key_path = "/etc/ssh/ssh_host_#{key_type}_key.pub"

    # This will contain ascii key data, or nil.
    existing_key =
      File.exist?(private_key_path) &&
      File.read(private_key_path)

    if vault_item[key_type]
      # Successfully retrieved host keys from vault
      # If the private key from vault doesn't match the one on disk,
      # Replace the file on disk, regenerate the public key and reload SSH.
      Chef::Log.info("Syncing #{private_key_path} with #{key_type} key from vault")

      file private_key_path do
        user 'root'
        group 'root'
        mode '0400'
        content vault_item[key_type]
        sensitive true
      end

      # Generate a new public key when private key is updated
      execute "generate-#{key_type}-public-key" do
        umask 0222
        command "ssh-keygen -y -f #{private_key_path} > #{public_key_path}"
        subscribes :run, "file[#{private_key_path}]", :immediately
        notifies :reload, 'service[ssh]'
        action :nothing
      end

    elsif !vault_item[key_type] && existing_key
      # If we failed to get host keys,
      # read the files on disk and write them back to the chef server.
      # (This will also update the server with new key types.)
      Chef::Log.warn("Can't find #{key_type} key in vault!")
      Chef::Log.warn("Creating #{key_type} key in vault.")
      vault_item[key_type] = existing_key
      vault_item.save
    else
      # Neither vault item nor node key exists
      Chef::Log.warn("Can't find ssh_host_keys/#{node[:fqdn]} in vault!")
      Chef::Log.warn("#{private_key_path} does not exist either!")
      Chef::Log.warn("Unsupported Key Type: #{key_type}")
    end

  end
end
