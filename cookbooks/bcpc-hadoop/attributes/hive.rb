default["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"] =
  'hive_table_stats'
default["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"] =
  'hive_table_stats'
default["bcpc"]["hadoop"]["hive"]["server2"]["authentication"] =
  'KERBEROS'
default["bcpc"]["hadoop"]["hive"]["server2"]["ldap_url"] =
  'ldap://bcpc.example.com'
default["bcpc"]["hadoop"]["hive"]["server2"]["ldap_domain"] =
  'bcpc.example.com'
default["bcpc"]["hadoop"]["hive"]["server2"]["port"] = '10000'
default["bcpc"]["hadoop"]["hive"]["warehouse"]["dir"] = \
  ::File.join(node[:bcpc][:hadoop][:hdfs_url], '/user/hive/warehouse')
default["bcpc"]["hadoop"]["hive"]["scratch"]["dir"] = \
  ::File.join(node[:bcpc][:hadoop][:hdfs_url], '/tmp/hive-scratch/')

# These will become key/value pairs in 'hive_site.xml'
default[:bcpc][:hadoop][:hive][:site_xml].tap do |site_xml|
  # hive.* options
  site_xml['hive.aux.jars.path'] =
    'file:///usr/share/java/mysql-connector-java.jar,' + 
    'file:///usr/hdp/current/hive-webhcat/share/hcatalog/hive-hcatalog-core.jar'
  site_xml['hive.exec.scratchdir'] = \
    ::File.join(node[:bcpc][:hadoop][:hive][:scratch][:dir], '${user.name}')
  site_xml['hive.metastore.client.socket.timeout'] = 3600
  site_xml['hive.metastore.execute.setugi'] = true
  site_xml['hive.server2.logging.operation.enabled'] = true
  site_xml['hive.server2.logging.operation.log.location'] =
    '/tmp/${user.name}/operation_logs'
  site_xml['hive.server2.logging.operation.verbose'] = true
  site_xml['hive.stats.autogather'] = true
  site_xml['hive.stats.dbclass'] = 'fs'
  site_xml['hive.stats.jdbcdriver'] = 'com.mysql.jdbc.Driver'
  site_xml['hive.support.concurrency'] = true
  site_xml['hive.warehouse.subdir.inherit.perms'] = true
  site_xml['hive.cluster.delegation.token.store.class'] =
    'org.apache.hadoop.hive.thrift.ZooKeeperTokenStore'
  site_xml['hive.cluster.delegation.token.store.zookeeper.connectString'] =
    '${hive.zookeeper.quorum}'

  # All other prefixes
  site_xml['datanucleus.autoCreateSchema'] = false
  site_xml['datanucleus.fixedDatastore'] = true
  site_xml['javax.jdo.option.ConnectionDriverName'] = 'com.mysql.jdbc.Driver'
  site_xml['javax.jdo.option.ConnectionUserName'] = "hive"
end

# These will become key/value pairs in 'hive-env.sh'
default[:bcpc][:hadoop][:hive][:env_sh].tap do |env_sh|
  env_sh[:HIVE_CONF_DIR] = '/etc/hive/conf.' + node.chef_environment
  env_sh[:JAVA_HOME] = node[:bcpc][:hadoop][:java]
  env_sh[:HADOOP_HEAPSIZE] = 1024
  env_sh[:HADOOP_OPTS] = 
    '-verbose:gc ' +
    '-XX:+PrintHeapAtGC ' +
    '-XX:+PrintGCDetails ' +
    '-XX:+PrintGCTimeStamps ' +
    '-XX:+PrintGCDateStamps ' +
    '-Xloggc:/var/log/hive/gc/' +
      'gc.log-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log ' +
    '-XX:+PrintTenuringDistribution ' +
    '-XX:+PrintGCApplicationStoppedTime ' +
    '-XX:+PrintGCApplicationConcurrentTime ' +
    '-XX:+UseConcMarkSweepGC ' +
    '-XX:+UseCMSInitiatingOccupancyOnly ' +
    '-XX:CMSInitiatingOccupancyFraction=70 ' +
    '-XX:+HeapDumpOnOutOfMemoryError ' +
    '-XX:HeapDumpPath=/var/log/hive/heap-dump-hive-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof ' +
    '-XX:+CMSClassUnloadingEnabled ' +
    '-XX:+UseParNewGC ' + 
    '-XX:+ExitOnOutOfMemoryError ' +
    "-agentpath:#{node['bcpc-hadoop']['jvmkill']['lib_file']}"

  env_sh[:HIVE_LOG_DIR] = "/var/log/hive"
  env_sh[:HIVE_PID_DIR] = "/var/run/hive"
  env_sh[:HIVE_IDENT_STRING] = "hive"
end
