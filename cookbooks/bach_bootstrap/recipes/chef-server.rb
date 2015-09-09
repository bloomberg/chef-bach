#
# Cookbook Name:: bach_bootstrap
# Recipe:: chef-server
#
include_recipe 'bach_common::proxy'

cache_path = Chef::Config[:file_cache_path]
chef_path = "#{cache_path}/chef-server-core_12.1.2-1_amd64.deb"

remote_file chef_path do
  source "https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/precise/chef-server-core_12.1.2-1_amd64.deb"
  mode 0444
  checksum '436c08c5b38705e19924a32f0885dd7f0f24a52c69a0259e93263dabf4b22ecb'
end

chef_ingredient 'chef-server' do
  version '12.1.2'
  package_source chef_path
  config <<-EOS.gsub(/^ {4}/,'')
    topology "standalone"
    api_fqdn "#{node['chef-server']['api_fqdn']}"
    #{node['chef-server']['configuration']}
  EOS
  action :install
end

ingredient_config 'chef-server' do
  notifies :reconfigure, 'chef_ingredient[chef-server]', :immediately
end

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
