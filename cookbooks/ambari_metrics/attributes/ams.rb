# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Attribute :: ams.rb
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

default['ams']['metrics']['site_xml'].tap do |site_xml|
  site_xml['failover.strategy'] = 'round-robin'
  site_xml['phoenix.query.maxGlobalMemoryPercentage'] = 25
  site_xml['phoenix.spool.directory'] = '/tmp'
  site_xml['timeline.metrics.aggregator.checkpoint.dir'] = \
    '/var/lib/ambari-metrics-collector/checkpoint'
  site_xml['timeline.metrics.aggregators.skip.blockcache.enabled'] = false
  site_xml['timeline.metrics.cache.commit.interval'] = 10
  site_xml['timeline.metrics.cache.enabled'] = true
  site_xml['timeline.metrics.cache.size'] = 200
  site_xml['timeline.metrics.cluster.aggregate.splitpoints'] = 'mem_total'
  site_xml['timeline.metrics.cluster.aggregation.sql.filters'] = \
    'sdisk\_%,boottime'
  site_xml['timeline.metrics.cluster.aggregator.daily.
    checkpointCutOffMultiplier'] = 2
  site_xml['timeline.metrics.cluster.aggregator.daily.disabled'] = false
  site_xml['timeline.metrics.cluster.aggregator.daily.interval'] = 86_400
  site_xml['timeline.metrics.cluster.aggregator.daily.ttl'] = 63_072_000
  site_xml['timeline.metrics.cluster.aggregator.hourly.
    checkpointCutOffMultiplier'] = 2
  site_xml['timeline.metrics.cluster.aggregator.hourly.disabled'] = false
  site_xml['timeline.metrics.cluster.aggregator.hourly.interval'] = 3600
  site_xml['timeline.metrics.cluster.aggregator.hourly.ttl'] = 31_536_000
  site_xml['timeline.metrics.cluster.aggregator.interpolation.enabled'] = true
  site_xml['timeline.metrics.cluster.aggregator.minute.
    checkpointCutOffMultiplier'] = 2
  site_xml['timeline.metrics.cluster.aggregator.minute.disabled'] = false
  site_xml['timeline.metrics.cluster.aggregator.minute.interval'] = 300
  site_xml['timeline.metrics.cluster.aggregator.minute.ttl'] = 2_592_000
  site_xml['timeline.metrics.cluster.aggregator.second.
    checkpointCutOffMultiplier'] = 2
  site_xml['timeline.metrics.cluster.aggregator.second.disabled'] = false
  site_xml['timeline.metrics.cluster.aggregator.second.interval'] = 120
  site_xml['timeline.metrics.cluster.aggregator.second.timeslice.interval'] = 30
  site_xml['timeline.metrics.cluster.aggregator.second.ttl'] = 259_200
  site_xml['timeline.metrics.daily.aggregator.minute.interval'] = 86_400
  site_xml['timeline.metrics.downsampler.topn.function'] = 'max'
  site_xml['timeline.metrics.downsampler.topn.metric.patterns'] = \
    'dfs.NNTopUserOpCounts.windowMs=60000.op=__%.user=%,
    dfs.NNTopUserOpCounts.windowMs=300000.op=__%.user=%,
    dfs.NNTopUserOpCounts.windowMs=1500000.op=__%.user=%'
  site_xml['timeline.metrics.downsampler.topn.value'] = 10
  site_xml['timeline.metrics.hbase.compression.scheme'] = 'SNAPPY'
  site_xml['timeline.metrics.hbase.data.block.encoding'] = 'FAST_DIFF'
  site_xml['timeline.metrics.hbase.init.check.enabled'] = true
  site_xml['timeline.metrics.host.aggregate.splitpoints'] = 'mem_total'
  site_xml['timeline.metrics.host.aggregator.daily.
    checkpointCutOffMultiplier'] = 2
  site_xml['timeline.metrics.host.aggregator.hourly.disabled'] = false
  site_xml['timeline.metrics.host.aggregator.hourly.interval'] = 3600
  site_xml['timeline.metrics.host.aggregator.hourly.ttl'] = 2_592_000
  site_xml['timeline.metrics.host.aggregator.minute.
    checkpointCutOffMultiplier'] = 2
  site_xml['timeline.metrics.host.aggregator.minute.disabled'] = false
  site_xml['timeline.metrics.host.aggregator.minute.interval'] = 300
  site_xml['timeline.metrics.host.aggregator.minute.ttl'] = 604_800
  site_xml['timeline.metrics.host.aggregator.ttl'] = 86_400
  site_xml['timeline.metrics.service.checkpointDelay'] = 60
  site_xml['timeline.metrics.service.cluster.aggregator.appIds'] = \
    'datanode,nodemanager,hbase'
  site_xml['timeline.metrics.service.default.result.limit'] = 15_840
  site_xml['timeline.metrics.service.handler.thread.count'] = 20
  site_xml['timeline.metrics.service.http.policy'] = 'HTTP_ONLY'
  site_xml['timeline.metrics.service.metadata.filters'] = 'ContainerResource'
  site_xml['timeline.metrics.service.operation.mode'] = 'embedded'
  site_xml['timeline.metrics.service.resultset.fetchSize'] = 2000
  site_xml['cluster.zookeeper.property.clientPort'] = \
    node['ams']['cluster']['zookeeper']['client_port'].to_s
  site_xml['cluster.zookeeper.quorum'] = \
    node['ams']['cluster']['zookeeper_quorum']
  site_xml['timeline.metrics.sink.report.interval'] = 60
  site_xml['timeline.metrics.sink.collection.period'] = 10
  site_xml['timeline.metrics.service.webapp.address'] = '0.0.0.0:6188'
  site_xml['timeline.metrics.service.watcher.timeout'] = 30
  site_xml['timeline.metrics.service.watcher.initial.delay'] = 600
  site_xml['timeline.metrics.service.watcher.disabled'] = false
  site_xml['timeline.metrics.service.watcher.delay'] = 30
  site_xml['timeline.metrics.service.use.groupBy.aggregators'] = true
  site_xml['timeline.metrics.service.rpc.address'] = '0.0.0.0:60200'
end
