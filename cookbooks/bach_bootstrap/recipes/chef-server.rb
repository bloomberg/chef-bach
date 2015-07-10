#
# Cookbook Name:: bach_bootstrap
# Recipe:: chef-server
#
require 'yaml'

include_recipe 'bach_common::proxy'

#
# This should really be replaced with our own cookbook.  The upstream
# cookbook provided by Chef, inc. requires your chef servers to have
# internet access.
#
include_recipe 'chef-server'

bach_user_path = '/home/vagrant/bach_user.pem'
bach_validator_path = '/home/vagrant/bach_validator.pem'

execute 'create-bach-user' do
  command <<-EOM.gsub(/^ {4}/,'')
    chef-server-ctl user-create \
      #{node['bach']['cluster']['user']['name']} \
      #{node['bach']['cluster']['user']['longname']} \
      #{node['bach']['cluster']['user']['email']} \
      #{node['bach']['cluster']['user']['password']} \
      --filename #{bach_user_path}
  EOM
  sensitive true
  not_if "chef-server-ctl user-list | grep '^bach$'"
end

execute 'create-bach-organization' do
  command <<-EOM.gsub(/^ {4}/,'')
  chef-server-ctl org-create #{node['bach']['cluster']['organization']['name']} \
    #{node['bach']['cluster']['organization']['longname']} \
    --association_user #{node['bach']['cluster']['user']['name']} > #{bach_validator_path}
  EOM
  not_if 'chef-server-ctl org-list | grep "^bach$"'
end
