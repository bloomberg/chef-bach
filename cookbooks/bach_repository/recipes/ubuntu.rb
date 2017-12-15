#
# Cookbook Name:: bach_repository
# Recipe:: ubuntu
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/ubuntu-14.04-hwe44-mini.iso" do
  source 'http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/' +
         'installer-amd64/current/images/xenial-netboot/mini.iso'
  mode 0444
  checksum 'db7a4116570ab4b9697ad5912aa5762e0d2b313ca712fabcd4dbfc6eaf300650'
end

