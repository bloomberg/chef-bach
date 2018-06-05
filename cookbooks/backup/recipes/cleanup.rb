# Cookbook Name::backup
# Recipe:: cleanup
# Cleans up the state of the storage cluster.
# Removes old configurations. Kills stale coordinators.
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

# creates the properties files for the service's oozie jobs.
def get_job_names(service)
  job_schedules = node[:backup][service][:schedules]
  job_schedules.inject([]) do |job_names, job_schedule|
    group, schedule = job_schedule
    names = (schedule[:jobs] || []).map do |job|
      "#{group}-#{job[:name] || File.basename(job[:path])}"
    end
    job_names.push(*names)
  end
end

# removes all local properties in #{path} not included in the #{filter}
# kills the stale oozie coordinators
def cleanup_service(filter, service, path)
  # Get a list of stale jobs
  # Checks the existing local properties files against current job set.
  stale_jobs = Dir.glob("#{path}/*.properties").select do |entry| 
    File.file? entry
  end.map do |filename| 
    /#{path}\/(.+).properties/.match(filename)[1]
  end.select do |name|
    !filter.include? name
  end

  puts "stale jobs: #{stale_jobs}"
  stale_jobs.each do |name|
    # remove the local properties file
    file "#{path}/#{name}.properties#delete" do
      path "#{path}/#{name}.properties"
      action :delete
    end

    # remove the hdfs properties file
    hdfs_file "#{path}/#{name}.properties#delete" do
      hdfs node[:backup][:namenode]
      path "#{node[:backup][service][:root]}/#{name}.properties"
      admin node[:backup][:user]
      action :delete
    end

    # kill stale oozie coordinator
    oozie_job "backup.#{service}.#{name}#kill" do
      url node[:backup][:oozie]
      name "backup.#{service}.#{name}"
      user node[:backup][:user]
      action :kill
      ignore_failure true
    end
  end
end

node[:backup][:services].each do |service|
  oozie_config_dir = node[:backup][service][:local][:oozie]
  jobnames = get_job_names(service)
  jobnames << "groups"
  cleanup_service(jobnames, service, oozie_config_dir)
end
