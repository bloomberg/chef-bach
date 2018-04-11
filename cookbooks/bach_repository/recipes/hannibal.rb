#
# Cookbook Name:: bach_repository
# Recipe:: hannibal
#
require 'pathname'
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

hbase_version = node[:hannibal][:hbase_version]
src_filename = "hannibal-hbase#{hbase_version}.tgz"

remote_file "#{bins_dir}/#{src_filename}" do
  source "#{node[:hannibal][:download_url]}/#{src_filename}"
  user 'root'
  group 'root'
  mode 0444
  checksum node[:hannibal][:checksum]["#{hbase_version}"]
end
