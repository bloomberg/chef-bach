# Cookbook Name:: backup
# Recipe:: bootstrap
# Creates the local backup bootstrap directory
# Generates the starter oozie configurations
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

# create the local configuration root
# holds local copies of the oozie configurations
directory node[:backup][:local][:root] do
  owner node[:backup][:user]
  group node[:backup][:user]
  mode "0755"
  action :create
end

node[:backup][:services].each do |service|
  # create the service backup root (drwxr-xr-x)
  directory node[:backup][service][:local][:root] do
    owner node[:backup][:user]
    group node[:backup][service][:user]
    mode "0755"
    action :create
  end

  # create the oozie config directory (drwxr-xr-x)
  directory node[:backup][service][:local][:oozie] do
    owner node[:backup][:user]
    group node[:backup][service][:user]
    mode "0755"
    action :create
  end

  # oozie config files
  oozie_config_dir = node[:backup][service][:local][:oozie]
  oozie_configs = %w(
    groups.properties
    groups.xml
    workflow.xml
    coordinator.xml
  )

  # source configuration templates
  oozie_configs.each do |config|
    template "#{oozie_config_dir}/#{config}" do
      source "#{service}/#{config}.erb"
      owner node[:backup][:user]
      group node[:backup][service][:user]
      mode "0755"
      action :create
      variables(
        service: service,
        groups: node[:backup][service][:schedules].keys,
        mode: '-rwxrwx---'
      )
    end
  end
end
