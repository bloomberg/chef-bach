# Pre-requisites
# git is installed 
# java and maven are installed

require 'fileutils'

hdfsdu_version = "#{node[:hdfsdu][:version]}"
target_filename = "hdfsdu-service-#{hdfsdu_version}-bin.zip"
target_filepath = "#{node[:hdfsdu][:bin_dir]}/#{target_filename}"
owner = "#{node[:hdfsdu][:owner]}"
group = "#{node[:hdfsdu][:group]}"
source_code_location = "#{Chef::Config['file_cache_path']}/hdfsdu"
file_mode = "#{node[:hdfsdu][:file_mode]}" 

git source_code_location do
   repository node[:hdfsdu][:repo_url]
   revision node[:hdfsdu][:repo_branch]
   action :sync
   not_if { ::File.exists?(target_filepath) }
end

bash "compile_hdfsdu" do
   cwd "#{source_code_location}/service"
   user owner
   group group
   code %Q{
      sed -iE 's/#{node[:hdfsdu][:default_db_port]}/#{node[:hdfsdu][:db_port]}/' src/main/java/com/twitter/hdfsdu/Database.java
      mvn clean assembly:assembly -DdescriptorId=bin
   }
   only_if { ::File.directory?(source_code_location) }
end

ruby_block "copy_hdfsdu_bin" do
   block do
      FileUtils.cp "#{source_code_location}/service/target/#{target_filename}", target_filepath
   end
   only_if { ::File.directory?(source_code_location) }
end

file target_filepath do
   mode '0755'
end

bash "create_hdfsdu_pig_tar" do
   cwd "#{source_code_location}/service"
   user owner
   group group
   code %Q{
      tar -zcvf #{node[:hdfsdu][:bin_dir]}/hdfsdu-pig-src-#{hdfsdu_version}.tgz ../pig/src
   }
   only_if { ::File.directory?(source_code_location) }
end

file "#{node[:hdfsdu][:bin_dir]}/hdfsdu-pig-src-#{hdfsdu_version}.tgz" do 
   mode '0755'
end

bash "cleanup" do
   cwd ::File.dirname(source_code_location)
   user owner
   group group
   code %Q{
      rm -rf hdfsdu/
   }
   only_if { ::File.directory?(source_code_location) }
end
