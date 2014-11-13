#
# Cookbook Name : bcpc
# Recipe Name : bootstrap_knife.rb
# Description : To create correct knife.rb file to work with reconfigured chef-server
#

template "/home/vagrant/chef-bcpc/.chef/knife.rb" do
  source "knife.rb.erb"
  owner "vagrant"
  group "vagrant"
  mode 00644
end
