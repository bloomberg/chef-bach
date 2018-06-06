# frozen_string_literal: true
# Cookbook :: ambari_metrics
# Attribute :: ams-hbase.rb
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
default['ams']['metrics']['hbase']['site_xml'].tap do |site_xml|
  site_xml['dfs.client.read.shortcircuit'] = true
  site_xml['hbase.client.scanner.caching'] = 10_000
  site_xml['hbase.client.scanner.timeout.period'] = 300_000
  site_xml['hbase.cluster.distributed'] = \
    node['ams']['hbase']['cluster_distributed']
  site_xml['hbase.hregion.majorcompaction'] = 0
  site_xml['hbase.hregion.max.filesize'] = 4_294_967_296
  site_xml['hbase.hregion.memstore.block.multiplier'] = 4
  site_xml['hbase.hregion.memstore.flush.size'] = 134_217_728
  site_xml['hbase.hstore.blockingStoreFiles'] = 200
  site_xml['hbase.hstore.flusher.count'] = 2
  site_xml['hbase.local.dir'] = '${hbase.tmp.dir}/local'
  site_xml['hbase.master.info.bindAddress'] = '0.0.0.0'
  site_xml['hbase.master.info.port'] = 61_310
  site_xml['hbase.master.normalizer.class'] = \
    'org.apache.hadoop.hbase.master.normalizer.SimpleRegionNormalizer'
  site_xml['hbase.master.port'] = 61_300
  site_xml['hbase.master.wait.on.regionservers.mintostart'] = 1
  site_xml['hbase.normalizer.enabled'] = false
  site_xml['hbase.normalizer.period'] = 600_000
  site_xml['hbase.regionserver.global.memstore.lowerLimit'] = 0.3
  site_xml['hbase.regionserver.global.memstore.upperLimit'] = 0.35
  site_xml['hbase.regionserver.info.port'] = 61_330
  site_xml['hbase.regionserver.port'] = 61_320
  site_xml['hbase.regionserver.thread.compaction.large'] = 2
  site_xml['hbase.regionserver.thread.compaction.small'] = 3
  site_xml['hbase.replication'] = false
  site_xml['hbase.rootdir'] = node['ams']['hbase']['rootdir']
  site_xml['hbase.rpc.timeout'] = 300_000
  site_xml['hbase.snapshot.enabled'] = false
  site_xml['hbase.tmp.dir'] = node['ams']['hbase']['tmpdir']
  site_xml['hbase.zookeeper.leaderport'] = \
    node['ams']['hbase']['zookeeper_leaderport']
  site_xml['hbase.zookeeper.peerport'] = \
    node['ams']['hbase']['zookeeper_peerport']
  site_xml['hbase.zookeeper.property.clientPort'] = \
    node['ams']['hbase']['zookeeper_clientport']
  site_xml['hbase.zookeeper.property.dataDir'] = '${hbase.tmp.dir}/zookeeper'
  site_xml['hbase.zookeeper.property.tickTime'] = 6000
  site_xml['hbase.zookeeper.quorum'] = node['ams']['hbase']['zookeeper_quorum']
  site_xml['hfile.block.cache.size'] = 0.3
  site_xml['phoenix.coprocessor.maxMetaDataCacheSize'] = 20_480_000
  site_xml['phoenix.coprocessor.maxServerCacheTimeToLiveMs'] = 60_000
  site_xml['phoenix.groupby.maxCacheSize'] = 307_200_000
  site_xml['phoenix.mutate.batchSize'] = 10_000
  site_xml['phoenix.query.keepAliveMs'] = 300_000
  site_xml['phoenix.query.maxGlobalMemoryPercentage'] = 15
  site_xml['phoenix.query.rowKeyOrderSaltedTable'] = true
  site_xml['phoenix.query.spoolThresholdBytes'] = 20_971_520
  site_xml['phoenix.query.timeoutMs'] = 300_000
  site_xml['phoenix.sequence.saltBuckets'] = 2
  site_xml['phoenix.spool.directory'] = '${hbase.tmp.dir}/phoenix-spool'
  site_xml['zookeeper.session.timeout'] = 120_000
  site_xml['zookeeper.session.timeout.localHBaseCluster'] = 120_000
  site_xml['zookeeper.znode.parent'] = \
    node['ams']['hbase']['zookeeper_znode_parent']
end
