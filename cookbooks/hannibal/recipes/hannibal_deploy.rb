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
service_dir = node[:hannibal][:service_dir]
owner = node[:hannibal][:owner]
group = node[:hannibal][:group]
user = node[:hannibal][:user]
file_mode = node[:hannibal][:file_mode]
exec_mode = node[:hannibal][:exec_mode]
endpoint = node[:hannibal][:service_endpoint]
timeout = node[:hannibal][:service_timeout]

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

template "hbase_site" do
   path "#{install_dir}/hannibal/conf/hbase-site.xml"
   source "hannibal_hbase-site.xml.erb"
   owner owner
   group group
   mode file_mode
   variables(:zk_hosts => node[:hannibal][:zookeeper_quorum])
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
   path "#{service_dir}/hannibal.conf"
   source "hannibal.upstart.conf.erb"
   owner owner
   group group
   mode file_mode
end

hannibal_dir = "#{install_dir}/hannibal"

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

service "hannibal" do
   provider Chef::Provider::Service::Upstart
   supports :status => true, :restart => true 
   action [:enable, :start]
   subscribes :restart, "template[application_conf]", :delayed
   notifies :run, "ruby_block[wait_for_hannibal]", :delayed 
end

# Confirm service did start; try until timeout and fail 
ruby_block "wait_for_hannibal" do
   block do
      wait_until_ready(endpoint, timeout)
   end
   action :nothing
end
