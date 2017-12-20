#
# Cookbook Name:: bach_repository
# Recipe:: opentsdb
#
# This recipe simply grabs the official deb package
# from the OpenTSDB github repo and puts it in the
# right place to be served from the bootstrap.
#

include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
opentsdb_deb = node['bach']['repository']['opentsdb']['package_name']

remote_file "#{bins_dir}/#{opentsdb_deb}" do
  source node['bach']['repository']['opentsdb']['download_url']
  checksum node['bach']['repository']['opentsdb']['checksum']
end
