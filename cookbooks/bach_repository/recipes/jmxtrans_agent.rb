#
# Cookbook Name:: bach_repository
# Recipe:: jmxtrans_agent
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
target_file = bins_dir + '/jmxtrans-agent-1.2.5.jar'

remote_file target_file do
  source node['bach']['repository']['jmxtrans_agent']['download_url']
  user 'root'
  group 'root'
  mode 0444
  checksum node['bach']['repository']['jmxtrans_agent']['checksum']
  not_if { File.exist?(target_file) }
end
