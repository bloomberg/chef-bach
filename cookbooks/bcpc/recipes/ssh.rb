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
include_recipe 'bcpc::chef_vault_install'

package 'openssh-client' do
  action :upgrade
end

package 'openssh-server' do
  action :upgrade
end

service 'ssh' do
  ignore_failure true
  action :enable
end

#
# The Init::Debian provider fails to start an already-started
# service on Ubuntu 14.04, due to bugs in their sysvinit
# compatibility scripts.
#
execute '/etc/init.d/ssh start' do
  action :run
  ignore_failure true
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode 00644
  notifies :restart, 'service[ssh]', :immediately
  variables lazy {{ listen_address: node[:bcpc][:management][:ip] }}

  # Don't rewrite the file unless we know the listen address is valid!
  only_if {
    bound_addresses = node[:network][:interfaces]
      .map { |_, ii| ii[:addresses] }
      .reduce({}, :merge)
      .select{ |_, data| data[:family].include?('inet') }.keys

    bound_addresses.include?(node[:bcpc][:management][:ip])
  }
end

ssh_key_types = %w{dsa ecdsa ed25519 rsa}

# First, try to retrieve existing host keys from the server.
ruby_block 'get-ssh-secrets-from-server' do
  block do
    require 'chef-vault'
    begin
      node.run_state[:bcpc_ssh_host_keys] =
        ChefVault::Item.load('ssh_host_keys', node[:fqdn])
    rescue Exception => ee
      # If we fail to load the vault, log the failure and create a vault.
      Chef::Log.warn("Failed to load ssh_host_keys/#{node[:fqdn]}:\n#{ee}")

      begin
        vault_item = ChefVault::Item.new('ssh_host_keys', node[:fqdn])
        vault_item.admins([get_bootstrap, node[:fqdn]].join(','))
        vault_item.search("fqdn:#{node[:fqdn]}")
        vault_item.save
        node.run_state[:bcpc_ssh_host_keys] = vault_item
      rescue Exception => eee
        # If we also fail to create, this node must not be an admin.
        Chef::Log.warn('Failed to create new vault ' \
                       "ssh_host_keys/#{node[:fqdn]}. " \
                       "Is this node an admin?\n#{eee}")
      end
    end
  end
  not_if { node[:fqdn] == get_bootstrap }
end

#
# If we failed to get host keys, read the files on disk and write them
# back to the chef server.
#
# (This block will also update the server with new key types.)
#
ruby_block 'read-ssh-secrets' do
  block do
    vault_item = node.run_state[:bcpc_ssh_host_keys]

    if vault_item.is_a?(ChefVault::Item)
      ssh_key_types.each do |key_type|
        private_key_path = "/etc/ssh/ssh_host_#{key_type}_key"
        public_key_path = "/etc/ssh/ssh_host_#{key_type}_key.pub"

        if vault_item[key_type].nil? && ::File.exist?(private_key_path)
          Chef::Log.info("Saving #{key_type} for #{node[:fqdn]}")
          vault_item[key_type] = ::File.read(private_key_path)
          vault_item.save
        end
      end
    else
      Chef::Log.warn("No vault item found for ssh_host_keys/#{node[:fqdn]}!")
    end
  end
  not_if { node[:fqdn] == get_bootstrap }
end

# If we successfully retrieved host keys, write files to disk and reload SSH.
ruby_block 'write-ssh-secrets' do
  block do
    vault_item = node.run_state[:bcpc_ssh_host_keys]

    if vault_item.is_a?(ChefVault::Item)
      ssh_key_types.each do |key_type|
        next unless vault_item[key_type]

        private_key_path = "/etc/ssh/ssh_host_#{key_type}_key"
        public_key_path = "/etc/ssh/ssh_host_#{key_type}_key.pub"

        # This will contain ascii key data, or nil.
        existing_key =
          ::File.exist?(private_key_path) &&
          ::File.read(private_key_path)

        #
        # If the private key saved on the server doesn't match the one
        # on disk, replace it and regenerate the public key.
        #
        if vault_item[key_type] != existing_key
          Chef::Log.info("Replacing #{key_type} host key for #{node[:fqdn]} " \
                         "with version from vault (ssh_keys/#{node[:fqdn]})")

          Chef::Resource::File.new(private_key_path,
                                   node.run_context).tap do |ff|
            ff.user 'root'
            ff.group 'root'
            ff.mode '0400'
            ff.content vault_item[key_type]
            ff.sensitive true if ff.respond_to?(:sensitive)
            ff.run_action(:create)
          end

          Chef::Resource::Execute.new("generate-#{key_type}-public-key",
                                      node.run_context).tap do |ee|
            ee.umask 0222
            ee.command "ssh-keygen -y -f #{private_key_path} > #{public_key_path}"
            ee.run_action(:run)
          end

          #
          # Since we have no run collection for our dynamically
          # generated resources, we have to use the ruby_block itself
          # to notify the SSH service.
          #
          self.notifies :restart, 'service[ssh]', :immediately
          self.resolve_notification_references
        end
      end
    else
      Chef::Log.warn("No vault item found for ssh_host_keys/#{node[:fqdn]}!")
    end
  end
  not_if { node[:fqdn] == get_bootstrap }
end
