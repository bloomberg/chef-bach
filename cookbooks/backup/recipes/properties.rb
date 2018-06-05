# Cookbook Name::backup
# Recipe:: properties
# Creates the local oozie job.properties files
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

# parses the job properties from an hdfs backup job
def parse_hdfs_properties(group, schedule, job)
  # override schedule parameters
  name = job[:name] || File.basename(job[:path])
  hdfs_src = job[:hdfs] || schedule[:hdfs]
  period = job[:period] || schedule[:period]
  bandwidth = node[:backup][:hdfs][:mapper][:bandwidth] ||
    node[:backup][:mapper][:bandwidth]
  queue = node[:backup][:hdfs][:queue] ||
    node[:backup][:queue]

  return {
    group: group,
    path: job[:path],
    basename: File.basename(job[:path]),
    jobname: "#{group}-#{name}",
    hdfs: hdfs_src,
    period: period,
    startdate: schedule[:start],
    enddate: schedule[:end],
    timeout: node[:backup][:hdfs][:timeout],
    bandwidth: bandwidth,
    queue: queue
  }
end

def parse_service_properties(service, group, schedule, job)
  case service.to_sym
  when :hdfs
    parse_hdfs_properties(group, schedule, job)
  else
    nil # service not found
  end
end

# parse job schedules and create properties files
node[:backup][:services].map do |service|
  node[:backup][service][:schedules].each do |group, schedule|
    schedule[:jobs].each do |job|

      # oozie job.properties
      oozie_config_dir = node[:backup][service][:local][:oozie]
      job_props = parse_service_properties(service, group, schedule, job)
      template "#{oozie_config_dir}/#{job_props[:jobname]}.properties" do
        source "#{service}/backup.properties.erb"
        owner node[:backup][:user]
        group node[:backup][service][:user]
        mode "0755"
        action :create
        variables job_props
      end

    end
  end
end
