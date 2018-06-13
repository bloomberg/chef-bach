# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Recipe :: ambari_metrics_collector
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
collector_lib_loc = node['ams']['collector']['lib_location']
ams_hbase_conf_loc = node['ams']['hbase_conf']['location']

directory ams_hbase_conf_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory File.join(collector_lib_loc, 'hbase-tmp') do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory File.join(collector_lib_loc, 'hbase') do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

template File.join(ams_hbase_conf_loc, 'hbase-site.xml') do
  source 'generic_site.xml.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  variables(lazy {
    { options: node['ams']['metrics']['hbase']['site_xml'] }
  })
end

template File.join(ams_hbase_conf_loc, 'hbase-env.sh') do
  source 'hbase-env.sh.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

template File.join(ams_hbase_conf_loc, 'hadoop-metrics2-hbase.properties') do
  source 'hadoop-metrics2-ams-hbase.properties.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

template File.join(ams_hbase_conf_loc, 'regionservers') do
  source 'regionservers.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end
collector_run_loc = node['ams']['collector']['run_location']

directory collector_run_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

collector_log_loc = node['ams']['collector']['log_location']

directory collector_log_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

collector_conf_loc = node['ams']['collector']['conf_location']

directory collector_conf_loc do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

directory File.join(collector_lib_loc, 'checkpoint') do
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  recursive true
end

template File.join(collector_conf_loc, 'ams-env.sh') do
  source 'ams-env.sh.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
end

template File.join(collector_conf_loc, 'hbase-site.xml') do
  source 'generic_site.xml.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  variables(lazy {
    { options: node['ams']['metrics']['hbase']['site_xml'] }
  })
end

template File.join(collector_conf_loc, 'ams-site.xml') do
  source 'generic_site.xml.erb'
  owner node['ams']['service']['user']
  group node['ams']['service']['group']
  mode '0755'
  variables(lazy {
    { options: node['ams']['metrics']['site_xml'] }
  })
end

execute 'stop ambari-metrics-collector' do
  command '/usr/sbin/ambari-metrics-collector ' \
   "--config #{collector_conf_loc} stop"
  returns 0
  user node['ams']['service']['user']
  action :nothing
  subscribes :run,
             "template[#{File.join(collector_conf_loc, 'ams-site.xml')}]",
             :immediately
  notifies :run, 'execute[cleanup-tmp-directory]', :immediately
  notifies :run, 'execute[start-ambari-metrics-collector]', :immediately
end

execute 'cleanup-tmp-directory' do
  command 'rm -rf /var/lib/ambari-metrics-collector/hbase-tmp/*.tmp'
  returns 0
  action :nothing
end

execute 'start-ambari-metrics-collector' do
  command '/usr/sbin/ambari-metrics-collector ' \
   "--config #{collector_conf_loc} start"
  returns 0
  user node['ams']['service']['user']
  action :nothing
end
