# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Recipe :: ambari_metrics_monitor
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
include_recipe 'ambari_metrics::ambari_metrics_assembly'

monitor_conf_loc = node['ams']['monitor']['conf_location']
monitor_log_loc = node['ams']['monitor']['log_location']
monitor_run_loc = node['ams']['monitor']['run_location']

directory monitor_conf_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory monitor_log_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory monitor_run_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

monitor_python_build_loc = node['ams']['monitor']['python_build_location']

directory monitor_python_build_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

template File.join(monitor_conf_loc, 'metric_monitor.ini') do
  source 'metric_monitor.ini.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

template File.join(monitor_conf_loc, 'metric_groups.conf') do
  source 'metric_groups.conf.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

template File.join(monitor_conf_loc, 'ams-env.sh') do
  source 'ams-env.sh.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

execute 'stop ambari-metrics-monitor' do
  command "/usr/sbin/ambari-metrics-monitor --config #{monitor_conf_loc} stop"
  returns 0
  user node['ams']['service']['user']
end

execute 'start ambari-metrics-monitor' do
  command "/usr/sbin/ambari-metrics-monitor --config #{monitor_conf_loc} start"
  returns 0
  user node['ams']['service']['user']
end
