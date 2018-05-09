# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Recipe :: ambari_metrics_grafana
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

grafana_conf_loc = node['ams']['grafana']['conf_location']
grafana_log_loc = node['ams']['grafana']['log_location']
grafana_lib_loc = node['ams']['grafana']['lib_location']
grafana_run_loc = node['ams']['grafana']['run_location']

directory grafana_conf_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory grafana_log_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory grafana_lib_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory grafana_run_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

template File.join(grafana_conf_loc, 'ams-grafana-env.sh') do
  source 'ams-grafana-env.sh.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

template File.join(grafana_conf_loc, 'ams-grafana.ini') do
  source 'ams-grafana.ini.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

execute 'stop ambari-metrics-grafana' do
  command '/usr/sbin/ambari-metrics-grafana stop'
  returns 0
  user node['ams']['service']['user']
  action :nothing
  subscribes :run,
             "template[#{File.join(grafana_conf_loc, 'ams-grafana.ini')}]",
             :immediately
  notifies :run, 'execute[start-ambari-metrics-grafana]', :immediately
end

execute 'start-ambari-metrics-grafana' do
  command '/usr/sbin/ambari-metrics-grafana start'
  returns 0
  user node['ams']['service']['user']
  action :nothing
end

grafana_datasource 'bach-ams-collector' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  datasource(
    type: 'ambarimetrics',
    url: node['ams']['collector']['url'],
    access: 'proxy',
    isdefault: true
  )
end

grafana_dashboard 'ams-hbase-home' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-ams-hbase-home',
    overwrite: true
  )
end

grafana_dashboard 'ams-hbase-misc' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-ams-hbase-misc',
    overwrite: true
  )
end

grafana_dashboard 'ams-hbase-regionservers' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-ams-hbase-regionservers',
    overwrite: true
  )
end

grafana_dashboard 'hbase-home' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hbase-home',
    overwrite: true
  )
end

grafana_dashboard 'hbase-misc' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hbase-misc',
    overwrite: true
  )
end

grafana_dashboard 'hbase-regionservers' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hbase-regionservers',
    overwrite: true
  )
end

grafana_dashboard 'hbase-tables' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hbase-tables',
    overwrite: true
  )
end

grafana_dashboard 'hbase-users' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hbase-users',
    overwrite: true
  )
end

grafana_dashboard 'hdfs-datanodes' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hdfs-datanodes',
    overwrite: true
  )
end

grafana_dashboard 'hdfs-home' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hdfs-home',
    overwrite: true
  )
end

grafana_dashboard 'hdfs-namenodes' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hdfs-namenodes',
    overwrite: true
  )
end

grafana_dashboard 'hdfs-topn' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hdfs-topn',
    overwrite: true
  )
end

grafana_dashboard 'hdfs-users' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-hdfs-users',
    overwrite: true
  )
end

grafana_dashboard 'system-home' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-system-home',
    overwrite: true
  )
end

grafana_dashboard 'system-servers' do
  host node['ams']['metrics_grafana']['host']
  port node['ams']['metrics_grafana']['port']
  admin_user node['ams']['metrics_grafana']['admin_user']
  admin_password node['ams']['metrics_grafana']['admin_password']
  dashboard(
    source: 'grafana-system-servers',
    overwrite: true
  )
end
