# Cookbook Name:: backup
# Recipe:: scheduler
# Launches the oozie coordinators to schedule periodic backups
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

# Run each oozie coordinator tracked by the backup service.
# Only runs the coordinator if it is not already RUNNING
node[:backup][:services].each do |service|
  node[:backup][service][:schedules].each do |group, schedule|
    schedule[:jobs].each do |job|

      # scheduler parameters
      name = job[:name] ? job[:name] : File.basename(job[:path])
      jobname = "#{group}-#{name}"
      oozie_config_dir = node[:backup][service][:local][:oozie]
      properties_file = "#{oozie_config_dir}/#{jobname}.properties"
      coordinator_file = "#{oozie_config_dir}/coordinator.xml"

      # restart oozie coordinators
      oozie_job "backup.#{service}.#{jobname}" do
        url node[:backup][:oozie]
        config properties_file
        user node[:backup][service][:user]
        action :run
        ignore_failure true
      end

    end
  end
end
