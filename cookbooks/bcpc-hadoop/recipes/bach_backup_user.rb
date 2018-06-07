# Cookbook Name:: bcpc-hadoop
# Recipe:: bach_backup_user
# Creates the user needed for hadoop cluster backup jobs
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

backup_user = node[:bcpc][:hadoop][:backup][:user]

user backup_user do
  action :create
  comment 'backup service user'
end

# make backup user an hdfs superuser
group 'hdfs' do
  members backup_user
  append true
end

configure_kerberos 'backup_kerberos' do
  service_name 'backup'
end
