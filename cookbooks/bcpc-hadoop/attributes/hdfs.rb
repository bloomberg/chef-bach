# vim: tabstop=2:shiftwidth=2:softtabstop=2
# Setting balancer andwidth to default value as per hdfs-default.xml
default['hadoop']['hdfs']['balancer']['bandwidth'] = 1_048_576
# balancer thread multiplier constant
default['hadoop']['hdfs']['balancer']['max_concurrent_moves_multiplier'] = 10

default['bcpc']['hadoop']['datanode']['xmx']['max_size'] = 4_096
default['bcpc']['hadoop']['datanode']['xmx']['max_ratio'] = 0.25
default['bcpc']['hadoop']['datanode']['max']['xferthreads'] = 16_384
default['bcpc']['hadoop']['namenode']['handler']['count'] = 100
# set to nil to calculate dynamically based on available memory
default['bcpc']['hadoop']['namenode']['xmx']['max_size'] = 1024
# # set to nil to calculate dynamically based on available memory
default['bcpc']['hadoop']['namenode']['xmn']['max_size'] = 128
default['bcpc']['hadoop']['namenode']['xmx']['max_ratio'] = 0.25
default['bcpc']['hadoop']['namenode']['jmx']['port'] = 10_111
default['bcpc']['hadoop']['namenode']['rpc']['port'] = 8020
default['bcpc']['hadoop']['namenode']['http']['port'] = 50_070
default['bcpc']['hadoop']['namenode']['https']['port'] = 50_470

default['bcpc']['hadoop']['datanode']['ipc']['port'] = 50_020
default['bcpc']['hadoop']['datanode']['port'] = 1004
default['bcpc']['hadoop']['datanode']['http']['port'] = 1006

# JMX port mappings
default['bcpc']['hadoop'].tap do |jmx|
  jmx['journalnode']['jmx']['port'] = 10110
  jmx['datanode']['jmx']['port'] = 10112
  jmx['namenode']['jmx']['port'] = 10111
end

default['bcpc']['hadoop']['hdfs']['dfs'].tap do |dfs|
  dfs['namenode']['audit']['log']['async'] = true
  dfs['webhdfs']['enabled'] = true
  dfs['client']['read']['shortcircuit'] = true
  dfs['domain']['socket']['path'] = '/var/run/hadoop-hdfs/dn._PORT'
  dfs['client']['file-block-storage-locations']['timeout'] = 3000
  dfs['datanode']['hdfs-blocks-metadata']['enabled'] = true
  dfs['namenode']['datanode']['registration']['ip-hostname-check'] = false
  dfs['namenode']['avoid']['read']['stale']['datanode'] = true
  dfs['namenode']['avoid']['write']['stale']['datanode'] = true
  dfs['hosts']['exclude'] = '/etc/hadoop/conf/dfs.exclude'
  dfs['datanode']['du']['reserved'] = 209_715_200 # 200 MB
  dfs['permissions']['superusergroup'] = 'hdfs'
  dfs['cluster']['administrators'] = 'hdfs'
  dfs['dfs']['ha']['automatic-failover']['enabled'] = true
end

default['bcpc']['hadoop']['hdfs']['site_xml'].tap do |site_xml|
  dfs = node['bcpc']['hadoop']['hdfs']['dfs']

  site_xml['dfs.replication'] =
    node['bcpc']['hadoop']['hdfs']['dfs_replication_factor']

  site_xml['dfs.namenode.audit.log.async'] =
    dfs['namenode']['audit']['log']['async']

  site_xml['dfs.datanode.sync.behind.writes'] = true
  site_xml['dfs.datanode.synconclose'] = true
  site_xml['dfs.namenode.stale.datanode.interval'] = 30_000

  site_xml['dfs.nameservices'] = node.chef_environment

  site_xml['dfs.datanode.failed.volumes.tolerated'] =
    node['bcpc']['hadoop']['hdfs']['failed_volumes_tolerated']

  site_xml["dfs.client.failover.proxy.provider.#{node.chef_environment}"] =
    'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'

  if node['bcpc']['hadoop']['hdfs']['HA']
    site_xml['dfs.ha.automatic-failover.enabled'] =
      dfs['dfs']['ha']['automatic-failover']['enabled']

    site_xml['dfs.ha.fencing.methods'] =
      'shell(/bin/true)'
  end

  site_xml['dfs.webhdfs.enabled'] =
    dfs['webhdfs']['enabled']

  site_xml['dfs.client.read.shortcircuit'] =
    dfs['client']['read']['shortcircuit']

  site_xml['dfs.domain.socket.path'] =
    dfs['domain']['socket']['path']

  site_xml['dfs.client.file-block-storage-locations.timeout'] =
    dfs['client']['file-block-storage-locations']['timeout']

  site_xml['dfs.datanode.hdfs-blocks-metadata.enabled'] =
    dfs['datanode']['hdfs-blocks-metadata']['enabled']

  site_xml['dfs.namenode.datanode.registration.ip-hostname-check'] =
    dfs['namenode']['datanode']['registration']['ip-hostname-check']

  site_xml['dfs.namenode.avoid.read.stale.datanode'] =
    dfs['namenode']['avoid']['read']['stale']['datanode']

  site_xml['dfs.namenode.avoid.write.stale.datanode'] =
    dfs['namenode']['avoid']['write']['stale']['datanode']

  site_xml['dfs.hosts.exclude'] =
    dfs['hosts']['exclude']

  site_xml['dfs.datanode.du.reserved'] =
    dfs['datanode']['du']['reserved']

  site_xml['dfs.blocksize'] =
    node['bcpc']['hadoop']['hdfs']['dfs_blocksize']

  site_xml['dfs.datanode.max.transfer.threads'] =
    node['bcpc']['hadoop']['datanode']['max']['xferthreads']

  site_xml['dfs.namenode.handler.count'] =
    node['bcpc']['hadoop']['namenode']['handler']['count']

  site_xml['dfs.client.socket-timeout'] =
    30_000
end

# hdfs bach web attributes
default['bcpc']['bach_web']['service_ports']['namenode_ui'] = {
  'desc' => 'HDFS Namenode UI port',
  'port' => node['bcpc']['hadoop']['namenode']['http']['port']
}
default['bcpc']['bach_web']['service_ports']['datanode_ui'] = {
  'desc' => 'HDFS Datanode UI port',
  'port' => node['bcpc']['hadoop']['datanode']['http']['port']
}

default['bcpc']['bach_web']['conn_lib']['hdfs_conn_lib_blacklist'] = []
default['bcpc']['bach_web']['files']['hdfs_conn_lib_blacklist'] = {
  'desc' => 'HDFS conn lib blacklist file',
  'path' => 'files/hdfs/blacklist.conf'
}
