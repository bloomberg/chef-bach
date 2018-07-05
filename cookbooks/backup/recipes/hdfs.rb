# Cookbook Name:: backup
# Recipe:: hdfs
# Uploads the bootstrap directory to HDFS
# Launches the group directory creation workflow
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

# upload the bootstrap directory to HDFS
hdfs_directory node[:backup][:root] do
  hdfs node[:backup][:namenode]
  source node[:backup][:local][:root]
  path File.dirname("#{node[:backup][:root]}")
  action :put
end

# launch the group dir creation workflow
node[:backup][:services].each do |service|
  oozie_config_dir = node[:backup][service][:local][:oozie]
  oozie_job "backup.groups.#{service}" do
    url node[:backup][:oozie]
    config "#{oozie_config_dir}/groups.properties"
    user node[:backup][:user]
    action :run
  end
end
