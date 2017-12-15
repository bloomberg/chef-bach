#
# Cookbook Name:: hdfsdu
# Recipe:: fetch_data
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Deploys an Oozie job to periodically fetch, process and store back
# into HDFS the processed HDFS usage data served by the HDFSDU web application

Chef::Recipe.send(:include, Hdfsdu::Helper)
Chef::Resource::Bash.send(:include, Hdfsdu::Helper)


user = node[:hdfsdu][:hdfsdu_user]
hdfsdu_vers = node[:hdfsdu][:version]
hdfsdu_pig_src_filename = "hdfsdu-pig-src-#{hdfsdu_vers}.tgz"
remote_filepath = "#{get_binary_server_url}#{hdfsdu_pig_src_filename}"
hdfsdu_pig_dir = "#{Chef::Config['file_cache_path']}/hdfsdu"
hdfsdu_oozie_dir = "#{hdfsdu_pig_dir}/oozie"

ark 'pig' do
  url remote_filepath
  path hdfsdu_pig_dir
  owner user
  action :put
  creates 'pig/src/test/resource/hdfsdu.pig'
end

%W(
  hdfsdu_pig_dir
  hdfsdu_oozie_dir
  #{hdfsdu_oozie_dir}/hdfsdu
  #{hdfsdu_oozie_dir}/hdfsdu/coordinatorConf
  #{hdfsdu_oozie_dir}/hdfsdu/scripts
  #{hdfsdu_oozie_dir}/hdfsdu/workflowApp
  #{hdfsdu_oozie_dir}/hdfsdu/workflowApp/input
  #{hdfsdu_oozie_dir}/hdfsdu/workflowApp/output
  #{hdfsdu_oozie_dir}/hdfsdu/workflowApp/lib
).each do |d|
  directory d do
    recursive true
    owner user
  end
end

%w(coordinator.xml coordinator.properties).each do |t|
  template "#{hdfsdu_oozie_dir}/hdfsdu/coordinatorConf/#{t}" do
    source "#{t}.erb"
    mode 0o0644
    owner user
  end
end

%w(fetchFsimage.sh formatUsage.sh).each do |t|
  template "#{hdfsdu_oozie_dir}/hdfsdu/scripts/#{t}" do
    source "#{t}.erb"
    mode 0o0655
    owner user
  end
end

template "#{hdfsdu_oozie_dir}/hdfsdu/workflowApp/workflow.xml" do
  source 'workflow.xml.erb'
  mode 0o0644
  owner user
end

bash 'compile_extract_sizes' do
  hdfsdu_pig_jar = \
    "#{hdfsdu_oozie_dir}/hdfsdu/workflowApp/lib/hdfsdu-pig-#{hdfsdu_vers}"
  dependent_jars = \
    Proc.new { find_paths(node['hdfsdu']['dependent_jars']).join(':') }
  extractsizes_class = 'com/twitter/hdfsdu/pig/piggybank/ExtractSizes*'
  cwd "#{hdfsdu_pig_dir}/pig/src/main/java"
  code lazy {
    %(
      javac -cp #{dependent_jars.call} \
        com/twitter/hdfsdu/pig/piggybank/ExtractSizes.java
      jar cvf #{hdfsdu_pig_jar}.jar #{extractsizes_class}.class
    )
  }
  user user
  creates "#{hdfsdu_pig_jar}.jar"
end

ruby_block 'copy_pig_script' do
  block do
    FileUtils.cp "#{hdfsdu_pig_dir}/pig/src/test/resources/hdfsdu.pig",
                 "#{hdfsdu_oozie_dir}/hdfsdu/scripts/hdfsdu.pig"
  end
  not_if { ::File.exist? "#{hdfsdu_oozie_dir}/hdfsdu/scripts/hdfsdu.pig" }
end

ruby_block 'copy_python_script' do
  block do
    FileUtils.cp "#{hdfsdu_pig_dir}/pig/src/main/python/leaf.py",
                 "#{hdfsdu_oozie_dir}/hdfsdu/scripts/leaf.py"
  end
  not_if { ::File.exist? "#{hdfsdu_oozie_dir}/hdfsdu/scripts/leaf.py" }
end

bash 'prepare_oozie_job' do
  job_freq = node['hdfsdu']['oozie_frequency']
  job_name = node['hdfsdu']['coordinator_job_name']
  # set our frequency to the default of minutes
  # if we do not have an EL expression
  unless job_freq.to_i == job_freq
    raise "Units other than bare minutes are not supported; got: #{job_freq}"
  end

  oozie_filter = "\"user=#{user};frequency=#{job_freq};" \
                 "unit=minutes;name=#{job_name};status=RUNNING\""
  cwd hdfsdu_oozie_dir
  code %(
    hdfs dfs -rm -R -skipTrash hdfsdu
    hdfs dfs -copyFromLocal hdfsdu
  )
  user user
  only_if %(
    oozie jobs -oozie #{node['hdfsdu']['oozie_url']} \
      -jobtype coordinator -filter #{oozie_filter} | \
    grep -q 'No Jobs match your criteria!'
  ), user: user
  notifies :run, 'bash[submit_oozie_job]', :immediately
end

bash 'submit_oozie_job' do
  cwd "#{hdfsdu_oozie_dir}/hdfsdu"
  code %(
    oozie job -oozie #{node['hdfsdu']['oozie_url']} \
      -config coordinatorConf/coordinator.properties -run
  )
  user user
  action :nothing
end
