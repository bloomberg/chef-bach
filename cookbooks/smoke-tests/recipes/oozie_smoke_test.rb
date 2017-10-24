# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# Cookbook Name:: hadoop-smoke-tests
# Recipe:: oozie_smoke_test
#
# Copyright 2016, Bloomberg Finance L.P.
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
require 'date'

test_user = node['hadoop_smoke_tests']['oozie_user']
workflow_path = node['hadoop_smoke_tests']['wf_path']
coordinator_path = node['hadoop_smoke_tests']['wf']['co_path']
app_name = node['hadoop_smoke_tests']['app_name']
cache_dir = "#{Chef::Config['file_cache_path']}/oozie-smoke-test"

directory cache_dir do
end

template "#{cache_dir}/workflow.xml" do
  source 'smoke_test_xml.erb'
end

template "#{cache_dir}/smoke_test_coordinator.properties" do
  source 'smoke_test_job_properties.erb'
  variables(smoke: node['hadoop_smoke_tests']['wf'])
end

template "#{cache_dir}/coordinator.xml" do
  source 'coordinator.xml.erb'
  variables(
    # rubocop:disable Layout/IndentHash
    appname: app_name,
    start_date: DateTime.now.strftime('%Y-%m-%dT%H:%MZ'),
    end_date: DateTime.now.next_year(10).strftime('%Y-%m-%dT%H:%MZ'),
    workflow: workflow_path,
    frequency: '${coord:minutes(10)}'
  )
  # rubocop:enable Layout/IndentHash
end

execute "create HDFS coordinator path #{coordinator_path}" do
  command "hdfs dfs -mkdir -p #{coordinator_path}"
  user test_user
end

execute "create HDFS workflow path #{workflow_path}" do
  command "hdfs dfs -mkdir -p #{workflow_path}"
  user test_user
end

execute "upload coordinator to #{coordinator_path}" do
  command "hdfs dfs -copyFromLocal -f \
  #{cache_dir}/coordinator.xml #{coordinator_path}"
  user test_user
  not_if "hdfs dfs -test -f #{coordinator_path}/coordinator.xml",
         :user => test_user
end

execute "upload workflow to #{workflow_path}" do
  command "hdfs dfs -copyFromLocal -f #{cache_dir}/workflow.xml \
  #{workflow_path}" 
  user test_user
  not_if "hdfs dfs -test -f #{workflow_path}/workflow.xml",
         :user => test_user
end

template "#{cache_dir}/send_to_graphite.sh" do
  source "send_to_graphite_sh.erb"
  variables ({
    carbon_receiver: node['hadoop_smoke_tests']['carbon-line-receiver'],
    carbon_port: node['hadoop_smoke_tests']['carbon-line-port']
  })
end

execute "upload send_to_graphite.sh" do
  command "hdfs dfs -copyFromLocal -f #{cache_dir}/send_to_graphite.sh \
  #{workflow_path}"
  user test_user
  not_if "hdfs dfs -test -f #{workflow_path}/send_to_graphite.sh",
    :user => test_user
end

Chef::Resource::RubyBlock.send(:include, HadoopSmokeTests::OozieHelper)

ruby_block 'smoke test coordinator status' do
  block do
    status_query = submit_command_running_host(
      test_user, "jobs -jobtype coordinator")
    node.run_state['need_coordinator_submit'] = 
      if status_query == nil then
        false
      else
        (status_query.each_line.select {
         | line | (line.include? app_name) && 
           (line.include? 'RUNNING') }).empty?
      end
    end
end

ruby_block 'submit oozie smoke test' do
  block do
    submit_workflow_running_host(
      test_user,
      "#{cache_dir}/smoke_test_coordinator.properties")
  end
  only_if { node.run_state['need_coordinator_submit'] == true }
end
