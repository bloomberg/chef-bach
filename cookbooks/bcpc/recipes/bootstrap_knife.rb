#
# Cookbook Name : bcpc
# Recipe Name : bootstrap_knife.rb
#
# This recipe is provided for backwards compatibility with existing
# runlists.  It used to install a knife configuration based on a
# template.
#
# Now it uses the chef-client cookbook to accomplish the same task.
#

knife_path = '/home/vagrant/chef-bcpc/.chef/knife.rb'

file knife_path do
  action :create_if_missing
  content '# This was a dummy file created by Chef.'
  owner 'vagrant'
  group 'vagrant'
  mode 00644
end

link '/etc/chef/client.rb' do
  to knife_path
end

include_recipe 'chef-client::config'

edit_resource(:template, '/etc/chef/client.rb') do
  manage_symlink_source true
end
