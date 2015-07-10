#
# Cookbook Name:: bach_repository
# Recipe:: ubuntu
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/ubuntu-12.04-mini.iso" do
  source 'http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64/current/images/netboot/mini.iso'
  mode 0444
  checksum '7df121f07878909646c8f7862065ed7182126b95eadbf5e1abb115449cfba714'
end
