# Cookbook Name:: bach_backup_wrapper
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

# Resources here are run at compile time.
# This is necessary to avoid errors in bcpc-hadoop's resource search.

backup_user = node[:backup][:user]

# create hdfs home
execute 'hdfs home for backup service' do
  command "hdfs dfs -mkdir -p /user/#{backup_user}"
  user 'hdfs'
end

execute 'chown hdfs home for backup service' do
  command "hdfs dfs -chown #{backup_user} /user/#{backup_user}"
  user 'hdfs'
end
