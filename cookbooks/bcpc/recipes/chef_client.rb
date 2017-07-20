#
# Cookbook Name:: bcpc
# Recipe:: chef_client
#
# This recipe configures the chef-client on both the bootstrap node
# and clients.  It injects the environment's configured proxy into the
# configuration.
#
# Most configuration parameters are set in attributes/chef_client.rb
#

#
# On the bootstrap node, the chef-client config file lives inside the
# vagrant home directory, so that it can be shared by chef-client,
# knife, and chef-shell.
#
if node[:fqdn] == get_bootstrap
  # Symlink configuration for chef-client, chef-shell, and knife.
  link '/etc/chef/client.rb' do
    to '/home/vagrant/chef-bcpc/.chef/knife.rb'
  end

  # Remove the existing client.d directory, if present.
  execute 'rm -rf /etc/chef/client.d' do
    only_if{ File.directory?('/etc/chef/client.d') }
  end

  directory '/home/vagrant/.chef/client.d' do
    mode 0755
    user 'vagrant'
    group 'vagrant'
  end

  link '/etc/chef/client.d' do
    to '/home/vagrant/.chef/client.d'
  end

  link '/etc/chef/client.pem' do
    to "/home/vagrant/chef-bcpc/.chef/#{node[:fqdn]}.pem"
  end
end

include_recipe 'chef-client::config'

if node[:bcpc][:bootstrap][:proxy]
  #
  # We need to override the template in order to set environment
  # variables inside of the configuration.  (Knife and chef-shell
  # don't parse files inside client.d)
  #
  # bcpc/templates/default/client.rb.erb will render the original
  # upstream template, then append proxy environment variables.
  #
  edit_resource!(:template, "#{node['chef_client']['conf_dir']}/client.rb") do
    source 'client.rb.erb'
    cookbook 'bcpc'
  end
end

include_recipe 'chef-client::delete_validation'
