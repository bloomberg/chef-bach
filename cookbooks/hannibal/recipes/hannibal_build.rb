# Pre-requisites
# git is installed and proxies configured
# http and https proxies are set

hbase_version = "#{node[:hannibal][:hbase_version]}"
target_filename = "hannibal-hbase#{hbase_version}.tgz"
target_filepath = "#{node[:hannibal][:bin_dir]}/#{target_filename}"
owner = "#{node[:hannibal][:owner]}"
group = "#{node[:hannibal][:group]}"
source_code_location = "#{Chef::Config[:file_cache_path]}/hannibal"

# Install java
include_recipe "bcpc-hadoop::java_config"
include_recipe "java::default"

# Install maven
node.default['maven']['install_java'] = false
include_recipe "maven::default"

git source_code_location do
  repository node[:hannibal][:repo][:url]
  revision node[:hannibal][:repo][:branch]
  action :sync
  notifies :run, "bash[compile_hannibal]", :immediately
  notifies :run, "bash[cleanup]", :immediately
end

bash "compile_hannibal"  do
   cwd source_code_location
   user owner
   group group
   code %Q{
      export HANNIBAL_HBASE_VERSION=#{hbase_version}
      ./create_package
      cp target/#{target_filename} #{target_filepath}
      chmod 755 #{target_filepath}
   }
   action :nothing
end

bash "cleanup" do
   cwd ::File.dirname(source_code_location)
   user owner
   group group
   code %Q{
      rm -rf hannibal/
   }
   action :nothing
end
