# Cookbook Name : hannibal
# Recipe Name : hannibal_deploy
# Description : Download, configure and start hannibal

require 'fileutils'

hbase_version = node[:hannibal][:hbase_version]
src_filename = "hannibal-hbase#{hbase_version}.tgz"
src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
install_dir = node[:hannibal][:install_dir]
log_dir = node[:hannibal][:log_dir]
data_dir = node[:hannibal][:data_dir]
owner = node[:hannibal][:owner]
group = node[:hannibal][:group]
user = node[:hannibal][:user]
file_mode = node[:hannibal][:file_mode]
exec_mode = node[:hannibal][:exec_mode]
hannibal_dir="#{install_dir}/hannibal"

directory "Hannibal working directory" do
  path node[:hannibal][:working_dir]
  group group
  owner owner
  mode file_mode
  action :create
end

ark "hannibal" do
   url "#{node[:hannibal][:download_url]}/#{src_filename}"
   checksum node[:hannibal][:checksum]["#{hbase_version}"]
   path install_dir
   owner owner
   creates "start"
   action :put
   notifies :run, "ruby_block[set_hannibal_file_permissions]", :immediately
end

["#{log_dir}", "#{data_dir}"].each do |d|
   directory d do
      recursive true   
      owner user
   end
end

file "#{log_dir}/service.log" do
   owner user
   action :create_if_missing 
end

template "hannibal_hbase_site" do
  path "#{install_dir}/hannibal/conf/hbase-site.xml" 
  source 'generic_site.xml.erb'
  owner owner
  group group
  mode file_mode
  variables(:options => node['hannibal']['hbase_site'])
end

template "logger" do
   path "#{install_dir}/hannibal/conf/logger.xml"
   source "hannibal_logger.xml.erb"
   owner owner
   group group
   mode file_mode
end

template "application_conf" do
   path "#{install_dir}/hannibal/conf/application.conf"
   source "hannibal_application.conf.erb"
   owner owner
   group group
   mode file_mode
end

template "start_script" do
   path "#{install_dir}/hannibal/start"
   source "hannibal_start.erb"
   owner owner
   group group
end

template "hannibal_service" do
   path "/etc/init.d/hannibal"
   source "hannibal_init.rb"
   owner owner
   group group
   mode 0755
end

# Set directory permissions
[hannibal_dir, "#{hannibal_dir}/share", "#{hannibal_dir}/lib", "#{hannibal_dir}/bin", "#{hannibal_dir}/conf", "#{hannibal_dir}/start"].each do |d|
   directory d do
      mode '0755' 
   end
end

ruby_block "set_hannibal_file_permissions" do
   block do 
      FileUtils.chmod 0644, Dir["#{hannibal_dir}/lib/*"]
      FileUtils.chmod 0644, Dir["#{hannibal_dir}/conf/*"]
      FileUtils.chmod_R 0755, Dir["#{hannibal_dir}/conf/evolutions"]
   end
   action :nothing
end
