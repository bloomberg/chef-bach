# Cookbook Name : hdfsdu
# Recipe Name   : fetch_data.rb
# Description   : Setup oozie job to periodically fetch hdfs usage data

user = node[:hdfsdu][:hdfs_user] 
hdfsdu_version = node[:hdfsdu][:version]
hdfsdu_pig_src_filename = "hdfsdu-pig-src-#{hdfsdu_version}.tgz"
remote_filepath = "#{get_binary_server_url}#{hdfsdu_pig_src_filename}"
dependent_jars = node[:hdfsdu][:dependent_jars].join(':') 
hdfsdu_pig_dir = "#{Chef::Config['file_cache_path']}/hdfsdu"
hdfsdu_oozie_dir = "#{hdfsdu_pig_dir}/oozie"

ark "pig" do
   url remote_filepath
   path hdfsdu_pig_dir 
   owner user
   action :put
   creates "pig/src/test/resource/hdfsdu.pig"
end

%W{
hdfsdu_pig_dir
hdfsdu_oozie_dir
#{hdfsdu_oozie_dir}/hdfsdu
#{hdfsdu_oozie_dir}/hdfsdu/coordinatorConf
#{hdfsdu_oozie_dir}/hdfsdu/scripts
#{hdfsdu_oozie_dir}/hdfsdu/workflowApp
#{hdfsdu_oozie_dir}/hdfsdu/workflowApp/input
#{hdfsdu_oozie_dir}/hdfsdu/workflowApp/output
#{hdfsdu_oozie_dir}/hdfsdu/workflowApp/lib
}.each do |d|
   directory d do
      recursive true
      owner user
   end
end

["coordinator.xml", "coordinator.properties"].each do |t|
   template "#{hdfsdu_oozie_dir}/hdfsdu/coordinatorConf/#{t}" do
      source "#{t}.erb"
      mode 0644
      owner user
   end
end

["fetchFsimage.sh", "formatUsage.sh"].each do |t|
   template "#{hdfsdu_oozie_dir}/hdfsdu/scripts/#{t}" do
      source "#{t}.erb"
      mode 0655
      owner user
   end
end

template "#{hdfsdu_oozie_dir}/hdfsdu/workflowApp/workflow.xml" do
   source "workflow.xml.erb"
   mode 0644
   owner user
end

bash "compile_extract_sizes" do
   cwd "#{hdfsdu_pig_dir}/pig/src/main/java"
   code %Q{
      javac -cp #{dependent_jars} com/twitter/hdfsdu/pig/piggybank/ExtractSizes.java
      jar cvf #{hdfsdu_oozie_dir}/hdfsdu/workflowApp/lib/hdfsdu-pig-#{hdfsdu_version}.jar com/twitter/hdfsdu/pig/piggybank/ExtractSizes*.class
   }
   user user
end

ruby_block "copy_pig_script" do
   block do
      FileUtils.cp "#{hdfsdu_pig_dir}/pig/src/test/resources/hdfsdu.pig", "#{hdfsdu_oozie_dir}/hdfsdu/scripts/hdfsdu.pig"
   end
end

ruby_block "copy_python_script" do
   block do
      FileUtils.cp "#{hdfsdu_pig_dir}/pig/src/main/python/leaf.py", "#{hdfsdu_oozie_dir}/hdfsdu/scripts/leaf.py"
   end
end

bash "prepare_oozie_job" do
   cwd hdfsdu_oozie_dir
   code %Q{
      hdfs dfs -rm -R -skipTrash hdfsdu
      hdfs dfs -copyFromLocal hdfsdu 
   }
   user user
   not_if "oozie jobs -oozie #{node[:hdfsdu][:oozie_url]} -filter user=#{user}\\;frequency=#{node[:hdfsdu][:oozie_frequency]}\\;status=RUNNING -jobtype coordinator | grep \"#{node[:hdfsdu][:coordinator_job_name]}\""
end

bash "submit_oozie_job" do
   cwd "#{hdfsdu_oozie_dir}/hdfsdu"
   code %Q{
     oozie job -oozie #{node[:hdfsdu][:oozie_url]} -config coordinatorConf/coordinator.properties -run 
   }
   user user
   action :nothing
   subscribes :run, "bash[prepare_oozie_job]", :immediately
end

directory hdfsdu_pig_dir do
   recursive true
   action :nothing
end
