#
# Cookbook Name:: bach_repository
# Recipe:: cirros
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/cirros-0.3.0-x86_64-disk.img" do
  source 'https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img'
  mode 0444
  checksum '648782e9287288630250d07531fed9944ecc3986764a6664f0bf6c050ec06afd'
end
