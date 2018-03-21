#
# Cookbook Name:: bach_repository
# Recipe:: jolokia_agent
#
require 'tmpdir'
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
jolokia_extract_dir = Dir.mktmpdir
jolokia_tar_file = bins_dir + '/jolokia-1.5.0-bin.tar.gz'
target_file = bins_dir + '/jolokia-jvm.jar'

remote_file jolokia_tar_file do
  source node['bach']['repository']['jolokia_agent']['download_url']
  user 'root'
  group 'root'
  mode 0444
  notifies :run, 'execute[extract_jolokia_tar]', :immediately
  not_if { File.exist?(target_file) }
end

execute 'extract_jolokia_tar' do
  command "tar xvf #{jolokia_tar_file} -C #{jolokia_extract_dir}"
  cwd bins_dir
  notifies :run, 'execute[copy_jolokia_agent_jar]', :immediately
  action :nothing
end

execute 'copy_jolokia_agent_jar' do
  command "cp #{jolokia_extract_dir}/jolokia-1.5.0/agents/jolokia-jvm.jar ."
  cwd bins_dir
  action :nothing
end
