# Cookbook Name:: backup
# HDFS Backup Attributes
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

### hdfs backups
default[:backup][:hdfs][:user] = node[:backup][:user]
default[:backup][:hdfs][:root] = "#{node[:backup][:root]}/hdfs"
default[:backup][:hdfs][:local][:root] = "#{node[:backup][:local][:root]}/hdfs"

# local oozie config dir
default[:backup][:hdfs][:local][:oozie] =
  "#{node[:backup][:hdfs][:local][:root]}/oozie"

## hdfs backup tuning parameters
# timeout in minutes before aborting distcp request
default[:backup][:hdfs][:timeout] = -1

# bandlimit in MB/s per mapper
default[:backup][:hdfs][:mapper][:bandwidth] = 25

### hdfs backup requests
default[:backup][:hdfs][:schedules] = {}

## NOTE: refer to files/default/hdfs/jobs.yml for the proper data scheme.
# default[:backup][:hdfs][:schedules] = YAML.load_file(File.join(
#   Chef::Config[:file_cache_path],
#   'cookbooks',
#   'backup',
#   'files/default/hdfs/jobs.yml'
# ))
