#
# Cookbook Name:: backup
# Custom oozie job resource
#
# Copyright 2018, Bloomberg Finance L.P.
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

resource_name :oozie_job
provides :oozie_job

property :name, String, name_property: true
property :url, String, required: true
property :config, String, required: true
property :user, String

action_class do
  include Oozie
end

action :run do
  Chef::Log.info("Starting oozie job: #{name}")
  client = Oozie::Client.new(url, user)

  # check if the job is already running
  job_id = client.get_id(name, 'coordinator', 'RUNNING')

  # start the service
  if job_id.nil?
    run_cmd = client.run(config, user)
    run_cmd.error!
  end
end

action :restart do
  Chef::Log.info("Rerunning oozie job: #{name}")
  client = Oozie::Client.new(url, user)

  # check if the job is already running
  job_id = client.get_id(name, 'coordinator', 'RUNNING')

  if job_id.nil?
    # start the service
    run_cmd = client.run(config, user)
    run_cmd.error!
  else
    # kill and restart the service
    kill_cmd = client.kill(job_id, user)
    kill_cmd.error!
    rerun_cmd = client.run(config, user)
    rerun_cmd.error!
  end
end

action :kill do
  Chef::Log.info("Killing oozie job: #{name}")
  client = Oozie::Client.new(url, user)

  # kill the service (if it exists)
  jobs_cmd = client.kill_jobs({ name: name }, "coordinator")
  jobs_cmd.error!
end

action :nothing do
end
