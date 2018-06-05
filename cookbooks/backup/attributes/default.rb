# Cookbook Name:: backup
# Default Attributes
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

## global backup properties
default[:backup][:user] = "backup"
default[:backup][:root] = "/backup"
default[:backup][:local][:root] = "/etc/backup"

# list of enabled backup services
default[:backup][:services] = [:hdfs]

# storage cluster
default[:backup][:namenode] = "hdfs://localhost:9000"
default[:backup][:jobtracker] = "localhost:8032"
default[:backup][:oozie] = "http://localhost:11000/oozie"
default[:backup][:queue] = "default"
