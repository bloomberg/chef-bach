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
  checksum 'eefab8ae8f25584c901e6e094482baa2974e9f321fe7ea7822659edeac279609'
end

