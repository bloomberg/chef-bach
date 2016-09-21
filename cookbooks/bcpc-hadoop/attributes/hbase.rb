# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# Cookbook: bcpc-hadoop
# File: attributes/hbase.rb
#
# Shared attributes for HBase configurations. hbase_env and
# hbase_config rely on these settings.
#
# Since attribute files are loaded in alphabetical order, it is
# important that filenames remain intact such that this file is loaded
# first.
#

#
# Flag to set whether the HBase master restart process was successful or not.
# This flag is usually saved on the node object.
#
default['bcpc']['hadoop']['hbase_master']['restart_failed'] = false

#
# Attribute to save the time when HBase master restart process failed.
# This flag is usually saved on the node object.
#
default['bcpc']['hadoop']['hbase_master']['restart_failed_time'] = ''

#
# Flag to set whether the HBase region server restart process was successful.
# This flag is usually saved on the node object.
#
default['bcpc']['hadoop']['hbase_regionserver']['restart_failed'] = false

#
# Attribute to save the time when HBase region server restart process failed.
# This flag is usually saved on the node object.
#
default['bcpc']['hadoop']['hbase_regionserver']['restart_failed_time'] = ''

default['bcpc']['hadoop']['hbase'].tap do |hbase|
  hbase['root_dir'] = "#{node['bcpc']['hadoop']['hdfs_url']}/hbase"
  hbase['bulkload_staging_dir'] = '/tmp/hbase'
  hbase['repl']['enabled'] = false
  hbase['repl']['peer_id'] = node.chef_environment.gsub('-','_')
  hbase['repl']['target'] = ''
  hbase['superusers'] = ['hbase']
  hbase['cluster']['distributed'] = true
  hbase['defaults']['for']['version']['skip'] = true
  hbase['dfs']['client']['read']['shortcircuit']['buffer']['size'] = 131072
  hbase['regionserver']['handler']['count'] = 128

  #
  # Interval in ms when HBase major compaction need to be
  # run. Disabled by default
  #
  hbase['major_compact']['time'] = 0

  hbase['bucketcache']['enabled'] = false
  hbase['blockcache']['size'] = 0.4
  hbase['bucketcache']['size'] = 1434
  hbase['bucketcache']['ioengine'] = 'offheap'
  hbase['bucketcache']['combinedcache']['percentage'] = 0.71
  hbase['shortcircuit']['read'] = false

  hbase['region'].tap do |region|
    region['replication']['enabled'] = false
    region['replica']['storefile']['refresh']['memstore']['multiplier'] = 4
    region['replica']['wait']['for']['primary']['flush'] = true
  end

  hbase['hregion']['memstore']['block']['multiplier'] = 8
  hbase['ipc']['client']['specificthreadforwriting'] = true
  hbase['client']['primarycalltimeout']['get'] = 100000
  hbase['client']['primarycalltimeout']['multiget'] = 100000
  hbase['meta']['replica']['count'] = 3
  hbase['ipc']['warn']['response']['time'] = 250
  hbase['ipc']['warn']['response']['size'] = 1048576
end

default['bcpc']['hadoop']['hbase_master'].tap do |hbase_master|
  hbase_master['hfilecleaner']['ttl'] = 3600000
  hbase_master['jmx']['port'] = 10101
  hbase_master['gc_thread']['cpu_ratio'] = 0.2
  hbase_master['cmsinitiatingoccupancyfraction'] = 70
  hbase_master['PretenureSizeThreshold'] = '1m'
  hbase_master['xmn']['size'] = 256
  hbase_master['xms']['size'] = 1024
  hbase_master['xmx']['size'] = 1024
end

default['bcpc']['hadoop']['hbase_rs'].tap do |hbase_rs|
  hbase_rs['coprocessor']['abortonerror'] = true
  hbase_rs['jmx']['port'] = 10102
  hbase_rs['xmn']['size'] = 256
  hbase_rs['xms']['size'] = 1024
  hbase_rs['xmx']['size'] = 1024
  hbase_rs['mx_dir_mem']['size'] = 256
  hbase_rs['hdfs_dir_mem']['size'] = 128
  hbase_rs['gc_thread']['cpu_ratio'] = 0.4
  hbase_rs['memstore']['upperlimit'] = 0.4
  hbase_rs['memstore']['lowerlimit'] = 0.2
  hbase_rs['storefile']['refresh']['all'] = false
  hbase_rs['storefile']['refresh']['period'] = 30000
  hbase_rs['cmsinitiatingoccupancyfraction'] = 70
  hbase_rs['PretenureSizeThreshold'] = '1m'
end

# Apache Phoenix related attributes
default['bcpc']['hadoop']['phoenix']['tracing']['enabled'] = false

bucketcache_size = node['bcpc']['hadoop']['hbase_rs'].tap do |hbase_rs|
  (hbase_rs['mx_dir_mem']['size'] -  hbase_rs['hdfs_dir_mem']['size']).floor
end

# These will become key/value pairs in 'hbase_site.xml'
default[:bcpc][:hadoop][:hbase][:site_xml].tap do |site_xml|
  site_xml['hbase.rootdir'] =
    node['bcpc']['hadoop']['hbase']['root_dir'].to_s

  site_xml['hbase.bulkload.staging.dir'] =
    node['bcpc']['hadoop']['hbase']['bulkload_staging_dir'].to_s

  site_xml['hbase.cluster.distributed'] =
    node['bcpc']['hadoop']['hbase']['cluster']['distributed'].to_s

  site_xml['hbase.hregion.majorcompaction'] =
    node['bcpc']['hadoop']['hbase']['major_compact']['time'].to_s

  site_xml['hbase.regionserver.ipc.address'] =
    node['bcpc']['floating']['ip'].to_s

  site_xml['hbase.master.ipc.address'] =
    node['bcpc']['floating']['ip'].to_s

  site_xml['hbase.defaults.for.version.skip'] =
    node['bcpc']['hadoop']['hbase']['defaults']['for']['version']['skip'].to_s

  site_xml['hbase.regionserver.wal.codec'] =
    'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'

  site_xml['hbase.region.server.rpc.scheduler.factory.class'] =
    'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'

  site_xml['hbase.rpc.controllerfactory.class'] =
    'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'

  site_xml['hbase.regionserver.handler.count'] =
    node['bcpc']['hadoop']['hbase']['regionserver']['handler']['count'].to_s

  site_xml['hbase.ipc.warn.response.time'] =
    node['bcpc']['hadoop']['hbase']['ipc']['warn']['response']['time'].to_s

  site_xml['hbase.ipc.warn.response.size'] =
    node['bcpc']['hadoop']['hbase']['ipc']['warn']['response']['size'].to_s

  # Why are these boolean parameters strings?
  site_xml['hbase.ipc.server.tcpnodelay'] = 'true'
  site_xml['hbase.replication'] = 'true'

  site_xml['hbase.coprocessor.abortonerror'] =
    node['bcpc']['hadoop']['hbase_rs']['coprocessor']['abortonerror']
end
