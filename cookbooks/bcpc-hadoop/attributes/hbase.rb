# vim: tabstop=2:shiftwidth=2:softtabstop=2
default['bcpc']['hadoop']['hbase']['root_dir'] = "#{node['bcpc']['hadoop']['hdfs_url']}/hbase"
default['bcpc']['hadoop']['hbase']['bulkload_staging_dir'] = "/tmp/hbase"
default["bcpc"]["hadoop"]["hbase"]["repl"]["enabled"] = false
default["bcpc"]["hadoop"]["hbase"]["repl"]["peer_id"] = node.chef_environment.gsub("-","_")
default["bcpc"]["hadoop"]["hbase"]["repl"]["target"] = ""
default["bcpc"]["hadoop"]["hbase"]["superusers"] = ["hbase"]
default["bcpc"]["hadoop"]["hbase"]["cluster"]["distributed"] = true
default["bcpc"]["hadoop"]["hbase"]["defaults"]["for"]["version"]["skip"] = true
default["bcpc"]["hadoop"]["hbase"]["dfs"]["client"]["read"]["shortcircuit"]["buffer"]["size"] = 131072
default["bcpc"]["hadoop"]["hbase"]["regionserver"]["handler"]["count"] = 128
# Interval in milli seconds when HBase major compaction need to be run. Disabled by default
default["bcpc"]["hadoop"]["hbase"]["major_compact"]["time"] = 0
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] = false
default["bcpc"]["hadoop"]["hbase_rs"]["coprocessor"]["abortonerror"] = true
default["bcpc"]["hadoop"]["hbase"]["blockcache"]["size"] = 0.4
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["size"] = 1434
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["ioengine"] = "offheap"
default["bcpc"]["hadoop"]["hbase"]["bucketcache"]["combinedcache"]["percentage"] = 0.71
default["bcpc"]["hadoop"]["hbase"]["shortcircuit"]["read"] = false
default["bcpc"]["hadoop"]["hbase"]["region"]["replication"]["enabled"] = false
default["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["storefile"]["refresh"]["memstore"]["multiplier"] = 4
default["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["wait"]["for"]["primary"]["flush"] = true
default["bcpc"]["hadoop"]["hbase"]["hregion"]["memstore"]["block"]["multiplier"] = 8
default["bcpc"]["hadoop"]["hbase"]["ipc"]["client"]["specificthreadforwriting"] = true
default["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["get"] = 100000
default["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["multiget"] = 100000
default["bcpc"]["hadoop"]["hbase"]["meta"]["replica"]["count"] = 3
default["bcpc"]["hadoop"]["hbase"]["ipc"]["warn"]["response"]["time"] = 250
default["bcpc"]["hadoop"]["hbase"]["ipc"]["warn"]["response"]["size"] = 1048576
default["bcpc"]["hadoop"]["hbase_master"]["hfilecleaner"]["ttl"] = 3600000
default["bcpc"]["hadoop"]["hbase_master"]["jmx"]["port"] = 10101
default["bcpc"]["hadoop"]["hbase_rs"]["jmx"]["port"] = 10102
default["bcpc"]["hadoop"]["hbase_rs"]["xmn"]["size"] = 256
default["bcpc"]["hadoop"]["hbase_rs"]["xms"]["size"] = 1024
default["bcpc"]["hadoop"]["hbase_rs"]["xmx"]["size"] = 1024
default["bcpc"]["hadoop"]["hbase_rs"]["mx_dir_mem"]["size"] = 256
default["bcpc"]["hadoop"]["hbase_rs"]["hdfs_dir_mem"]["size"] = 128
default["bcpc"]["hadoop"]["hbase_rs"]["gc_thread"]["cpu_ratio"] = 0.4
default["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["upperlimit"] = 0.4
default["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["lowerlimit"] = 0.2
default["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["all"] = false
default["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["period"] = 30000
default["bcpc"]["hadoop"]["hbase_rs"]["cmsinitiatingoccupancyfraction"] = 70
default["bcpc"]["hadoop"]["hbase_rs"]["PretenureSizeThreshold"] = "1m"
#Apache Phoenix related attributes 
default["bcpc"]["hadoop"]["phoenix"]["tracing"]["enabled"] = false


bucketcache_size = (node["bcpc"]["hadoop"]["hbase_rs"]["mx_dir_mem"]["size"] -  node["bcpc"]["hadoop"]["hbase_rs"]["hdfs_dir_mem"]["size"]).floor 

# These will become key/value pairs in 'hbase_site.xml'
default[:bcpc][:hadoop][:hbase][:site_xml].tap do |site_xml|
  site_xml['hbase.rootdir'] = "#{node['bcpc']['hadoop']['hbase']['root_dir']}"
  site_xml['hbase.bulkload.staging.dir'] = "#{node['bcpc']['hadoop']['hbase']['bulkload_staging_dir']}"
  # the below value will be defined in recipe and merged in 
  #site_xml['hbase.zookeeper.quorum'] = #{@zk_hosts.map{ |s| float_host(s[:hostname])}.join(",")}
  # the below value will be defined in recipe and merged in 
  #site_xml['hbase.zookeeper.property.clientPort'] = "#{node[:bcpc][:hadoop][:zookeeper][:port]}"
  site_xml['hbase.cluster.distributed'] = "#{node["bcpc"]["hadoop"]["hbase"]["cluster"]["distributed"]}"
  site_xml['hbase.hregion.majorcompaction'] = "#{node["bcpc"]["hadoop"]["hbase"]["major_compact"]["time"]}"
  # the below value will be defined in recipe and merged in 
  #site_xml['fail.fast.expired.active.master'] = "#{@master_hosts.length > 1 ? "true" : "false"}"
  # the below value will be defined in recipe and merged in 
  #site_xml['hbase.master.wait.on.regionservers.mintostart'] = "#{@rs_hosts.length/2+1}"
  site_xml['hbase.regionserver.ipc.address'] = "#{node["bcpc"]["floating"]["ip"]}"
  site_xml['hbase.master.ipc.address'] = "#{node["bcpc"]["floating"]["ip"]}"
  # the below value will be defined in recipe and merged in 
  #site_xml['hbase.regionserver.dns.nameserver'] = "#{@dns_server}"
  # the below value will be defined in recipe and merged in 
  #site_xml['hbase.master.dns.nameserver'] = "#{@dns_server}"
  site_xml['hbase.defaults.for.version.skip'] = "#{node["bcpc"]["hadoop"]["hbase"]["defaults"]["for"]["version"]["skip"]}"
  site_xml['hbase.regionserver.wal.codec'] = 'org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec'
  site_xml['hbase.region.server.rpc.scheduler.factory.class'] = 'org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory'
  site_xml['hbase.rpc.controllerfactory.class'] =  'org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory'
  # the below value will be defined in recipe and merged in 
  #if node[:bcpc][:hadoop][:kerberos][:enable] == true then
  #  site_xml['hbase.security.authorization'] = 'true'
  #  site_xml['hbase.superuser'] = node[:bcpc][:hadoop][:hbase][:superusers].join(',')
  #  site_xml['hbase.coprocessor.region.classes'] = 'org.apache.hadoop.hbase.security.token.TokenProvider,org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint,org.apache.hadoop.hbase.security.access.AccessController'
  #  site_xml['hbase.security.exec.permission.checks'] = 'true'
  #  site_xml['hbase.coprocessor.regionserver.classes'] = 'org.apache.hadoop.hbase.security.access.AccessController'
  #  site_xml['hbase.coprocessor.master.classes'] = 'org.apache.hadoop.hbase.security.access.AccessController'
  #  site_xml['hbase.security.authentication'] = 'kerberos'
  #  site_xml['hbase.master.kerberos.principal'] = "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:principal]}/" +
  #    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
  #  site_xml['hbase.master.keytab.file'] = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:keytab]}"
  #  site_xml['hbase.regionserver.kerberos.principal'] = "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
  #  site_xml['hbase.regionserver.keytab.file'] = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:keytab]}"
  #  site_xml['hbase.rpc.engine'] = 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
  #end
  site_xml['dfs.client.read.shortcircuit'] = node["bcpc"]["hadoop"]["hbase"]["shortcircuit"]["read"].to_s
  if node["bcpc"]["hadoop"]["hbase"]["shortcircuit"]["read"] == true then
    site_xml['dfs.domain.socket.path'] =  i'/var/run/hadoop-hdfs/dn._PORT'
    site_xml['dfs.client.read.shortcircuit.buffer.size'] = node["bcpc"]["hadoop"]["hbase"]["dfs"]["client"]["read"]["shortcircuit"]["buffer"]["size"].to_s
  end
  site_xml['hbase.regionserver.handler.count'] = node["bcpc"]["hadoop"]["hbase"]["regionserver"]["handler"]["count"].to_s
  site_xml['hbase.ipc.warn.response.time'] = node["bcpc"]["hadoop"]["hbase"]["ipc"]["warn"]["response"]["time"].to_s
  site_xml['hbase.ipc.warn.response.size'] = node["bcpc"]["hadoop"]["hbase"]["ipc"]["warn"]["response"]["size"].to_s
  site_xml['hbase.ipc.server.tcpnodelay'] = 'true'
  if node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] == true then
    site_xml['hbase.regionserver.global.memstore.upperLimit'] = node["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["upperlimit"].to_s
    site_xml['hfile.block.cache.size'] = node["bcpc"]["hadoop"]["hbase"]["blockcache"]["size"].to_s
    site_xml['hbase.bucketcache.size'] = bucketcache_size
    site_xml['hbase.bucketcache.ioengine '] = node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["ioengine"]
    site_xml['hbase.bucketcache.combinedcache.enabled'] = true
  end
  if node["bcpc"]["hadoop"]["hbase"]["region"]["replication"]["enabled"] == true then
    site_xml['hbase.regionserver.storefile.refresh.period'] = node["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["period"]
    site_xml['hbase.region.replica.replication.enabled'] = node["bcpc"]["hadoop"]["hbase"]["region"]["replication"]["enabled"]
    site_xml['hbase.master.hfilecleaner.ttl'] = node["bcpc"]["hadoop"]["hbase_master"]["hfilecleaner"]["ttl"]
    site_xml['hbase.meta.replica.count'] = node["bcpc"]["hadoop"]["hbase"]["meta"]["replica"]["count"]
    site_xml['hbase.regionserver.storefile.refresh.all'] = node["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["all"]
    site_xml['hbase.region.replica.storefile.refresh.memstore.multiplier'] = node["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["storefile"]["refresh"]["memstore"]["multiplier"]
    site_xml['hbase.region.replica.wait.for.primary.flush'] = node["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["wait"]["for"]["primary"]["flush"]
    site_xml['hbase.regionserver.global.memstore.lowerLimit'] = node["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["lowerlimit"]
    site_xml['hbase.hregion.memstore.block.multiplier'] = node["bcpc"]["hadoop"]["hbase"]["hregion"]["memstore"]["block"]["multiplier"]
    site_xml['hbase.ipc.client.specificThreadForWriting'] = node["bcpc"]["hadoop"]["hbase"]["ipc"]["client"]["specificthreadforwriting"]
    site_xml['hbase.client.primaryCallTimeout.get'] = node["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["get"]
    site_xml['hbase.client.primaryCallTimeout.multiget'] = node["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["multiget"]
  end
  site_xml['hbase.replication'] = 'true'
  site_xml['hbase.coprocessor.abortonerror'] = node["bcpc"]["hadoop"]["hbase_rs"]["coprocessor"]["abortonerror"] 
end
