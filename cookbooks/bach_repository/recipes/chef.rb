#
# Cookbook Name:: bach_repository
# Recipe:: chef
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/chef_12.4.1-1_amd64.deb" do
  source "https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/10.04/x86_64/chef_12.4.1-1_amd64.deb"
  mode 0444
  checksum 'bb2bdaa0c551fff21ccdf37dab75fc71374b521c419f1af51d1eab3ea2c791ba'
  # For whatever reason, these S3 mirrors are not very reliable.
  retries 8
end

remote_file "#{bins_dir}/chef-server-core_12.1.2-1_amd64.deb" do
  source "https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/precise/chef-server-core_12.1.2-1_amd64.deb"
  mode 0444
  checksum '436c08c5b38705e19924a32f0885dd7f0f24a52c69a0259e93263dabf4b22ecb'
end
