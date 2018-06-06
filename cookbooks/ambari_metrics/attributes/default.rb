# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Attribute :: default
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
default['ams']['java_home'] = '/usr/lib/jvm/java-8-oracle-amd64'
default['ams']['service']['user'] = 'ams'
default['ams']['service']['group'] = 'hadoop'
default['ams']['hbase']['zookeeper_znode_parent'] = '/ams-hbase'
default['ams']['hbase']['zookeeper_quorum'] = 'localhost'
default['ams']['cluster']['zookeeper_quorum'] = 'localhost'
default['ams']['hbase']['zookeeper_leaderport'] = '61388'
default['ams']['hbase']['zookeeper_clientport'] = '61181'
default['ams']['hbase']['zookeeper_peerport'] = '61288'
default['ams']['cluster']['zookeeper']['client_port'] = '2181'
default['ams']['metrics_collector']['hosts'] = 'localhost'
default['ams']['metrics_grafana']['host'] = 'localhost'
default['ams']['metrics_grafana']['port'] = 3000
default['ams']['metrics_collector']['port'] = 6188
default['ams']['metrics']['extendedperiod'] = 3600
default['ams']['metrics_grafana']['admin_user'] = 'admin'
default['ams']['metrics_grafana']['admin_password'] = 'admin'
default['ams']['collector']['url'] =
  "http://localhost:#{node['ams']['metrics_collector']['port']}"

default['ams']['hostname'] = 'localhost'
default['ams']['clustername'] = 'ambari'
default['ams']['']
default['ams']['hbase']['regionservers'] = 'localhost'
default['ams']['metrics']['period'] = '30'
default['ams']['collector']['heapsize'] = '512m'
default['ams']['number_open_files'] = '32768'
default['ams']['number_process'] = '65536'
default['ams']['hbase_conf']['location'] = '/etc/ams-hbase/conf'
default['ams']['collector']['lib_location'] =
  '/var/lib/ambari-metrics-collector'
default['ams']['collector']['run_location'] =
  '/var/run/ambari-metrics-collector'
default['ams']['collector']['log_location'] =
  '/var/log/ambari-metrics-collector'
default['ams']['collector']['conf_location'] =
  '/etc/ambari-metrics-collector/conf'
default['ams']['monitor']['log_location'] = '/var/log/ambari-metrics-monitor'
default['ams']['monitor']['run_location'] = '/var/run/ambari-metrics-monitor'
default['ams']['monitor']['conf_location'] = '/etc/ambari-metrics-monitor/conf'
default['ams']['monitor']['python_build_location'] =
  '/usr/lib/python2.6/site-packages/resource_monitoring/psutil/build'

default['ams']['grafana']['conf_location'] = '/etc/ambari-metrics-grafana/conf'
default['ams']['grafana']['log_location'] = '/var/log/ambari-metrics-grafana'
default['ams']['grafana']['lib_location'] = '/var/lib/ambari-metrics-grafana'
default['ams']['grafana']['run_location'] = '/var/run/ambari-metrics-grafana'
default['ams']['hbase']['rootdir'] =
  'file:///var/lib/ambari-metrics-collector/hbase'
default['ams']['hbase']['tmpdir'] =
  '/var/lib/ambari-metrics-collector/hbase-tmp'
default['ams']['hbase']['cluster_distributed'] = 'false'
default['ams']['hbase']['init_check'] = 'True'
default['ams']['hbase']['home'] = '/usr/lib/ams-hbase/'
default['ams']['timeline']['sink']['period'] = 10
default['ams']['timeline']['sink']['send_interval'] = 60_000
default['ams']['timeline']['rpc_client_port'] = 8020
default['ams']['metrics']['enable_time_threshold'] = 'false'
default['ams']['metrics']['enable_value_threshold'] = 'false'
default['ams']['metrics']['skip_disk_patterns'] = 'True'
default['ams']['metrics']['set_instance_id'] = 'false'
default['ams']['metrics']['emitter']['send_interval'] = 60
default['ams']['collector']['sleep_interval'] = 10
default['ams']['collector']['max_queue_size'] = 5000
default['ams']['collector']['failover_strategy'] = 'round-robin'
default['ams']['collector']['failover_strategy_blacklisted_interval_seconds'] =
  300
default['ams']['collector']['https_enabled'] = 'False'
default['ams']['grafana']['home_dir'] = '/usr/lib/ambari-metrics-grafana'
default['ams']['grafana']['dashboard_base_location'] = '/var/lib/ambari-server'\
'/resources/common-services/AMBARI_METRICS/0.1.0/package/'\
'files/grafana-dashboards/'
dashboard_base_location = node['ams']['grafana']['dashboard_base_location']

default['ams']['grafana']['dashboards'] = {
  'hdfs---namenodes' => File.join(dashboard_base_location,
                                  'HDP/grafana-hdfs-namenodes.json'),
  'yarn---applications' => File.join(dashboard_base_location,
                                     'HDP/grafana-yarn-applications.json'),
  'hdfs---datanodes' => File.join(dashboard_base_location,
                                  'HDP/grafana-hdfs-datanodes.json'),
  'yarn---nodemanagers' => File.join(dashboard_base_location,
                                     'HDP/grafana-yarn-nodemanagers.json'),
  'hdfs---home' => File.join(dashboard_base_location,
                             'HDP/grafana-hdfs-home.json'),
  'yarn---mr-jobhistoryserver' =>
  File.join(dashboard_base_location, 'HDP/grafana-yarn-jobhistoryserver.json'),
  'yarn---home' => File.join(dashboard_base_location,
                             'HDP/grafana-yarn-home.json'),
  'hbase---misc' => File.join(dashboard_base_location,
                              'HDP/grafana-hbase-misc.json'),
  'yarn---queues' => File.join(dashboard_base_location,
                               'HDP/grafana-yarn-queues.json'),
  'hbase---home' => File.join(dashboard_base_location,
                              'HDP/grafana-hbase-home.json'),
  'hbase---tables' => File.join(dashboard_base_location,
                                'HDP/grafana-hbase-tables.json'),
  'yarn---resourcemanager' =>
  File.join(dashboard_base_location, 'HDP/grafana-yarn-resourcemanagers.json'),
  'hdfs---users' => File.join(dashboard_base_location,
                              'HDP/grafana-hdfs-users.json'),
  'yarn---timelineserver' => File.join(dashboard_base_location,
                                       'HDP/grafana-yarn-timelineserver.json'),
  'hbase---users' => File.join(dashboard_base_location,
                               'HDP/grafana-hbase-users.json'),
  'hdfs---topn' => File.join(dashboard_base_location,
                             'HDP/grafana-hdfs-topn.json'),
  'ams-hbase---misc' => File.join(dashboard_base_location,
                                  'default/grafana-ams-hbase-misc.json'),
  'ams-hbase---home' => File.join(dashboard_base_location,
                                  'default/grafana-ams-hbase-home.json'),
  'system---home' => File.join(dashboard_base_location,
                               'default/grafana-system-home.json'),
  'ams-hbase---regionservers' =>
  File.join(dashboard_base_location,
            'default/grafana-ams-hbase-regionservers.json'),
  'system---servers' => File.join(dashboard_base_location,
                                  'default/grafana-system-servers.json')
}
