# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Recipe :: ambari_metrics_attribute_setup
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
set_hosts
ams_collector_nodes = node.run_state['cluster_def']
                          .fetch_cluster_def
                          .select do |h|
                            h[:runlist].include? 'recipe[bach_ambari_metrics'\
                            '::ambari_metrics_collector]'
                          end

if ams_collector_nodes.length.positive?
  ams_collector_hosts = ams_collector_nodes.map { |n| float_host(n[:fqdn]) }
                                           .join(',')
  node.force_default['ams']['metrics_collector']['hosts'] = ams_collector_hosts
end

node.force_default['ams']['cluster']['zookeeper_quorum'] =
  node['bcpc']['hadoop']['zookeeper']['servers']
  .map { |s| float_host(s['hostname']) }.join(',')

node.force_default['ams']['cluster']['zookeeper']['client_port'] =
  node['bcpc']['hadoop']['zookeeper']['port'].to_s

node.force_default['ams']['metrics_grafana']['host'] =
  float_host(node['fqdn'])

node.default['ams']['collector']['url'] =
  "http://#{node['ams']['metrics_collector']['hosts']}:"\
  "#{node['ams']['metrics_collector']['port']}"

include_recipe 'bach_ambari_metrics::ambari_metrics_ams_user'
