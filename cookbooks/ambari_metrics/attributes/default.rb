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
default['ams']['hostname'] = 'localhost'
default['ams']['clustername'] = 'ambari'
default['ams']['']
default['ams']['hbase']['regionservers'] = 'localhost'
default['ams']['collector']['heapsize'] = '512m'
default['ams']['number_open_files'] = '32768'
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
