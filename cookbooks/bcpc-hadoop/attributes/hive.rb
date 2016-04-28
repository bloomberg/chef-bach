default["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"] =
  "hive_table_stats"
default["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"] =
  "hive_table_stats"

# These will become key/value pairs in 'hive_site.xml'
default[:bcpc][:hadoop][:hive][:site_xml].tap do |site_xml|
  # hive.* options
  site_xml['hive.aux.jars.path'] =
    'file:///usr/share/java/mysql-connector-java.jar'
  site_xml['hive.exec.scratchdir'] =
    '/tmp/hive-${user.name}'
  site_xml['hive.metastore.client.socket.timeout'] = 3600
  site_xml['hive.metastore.execute.setugi'] = true
  site_xml['hive.server2.logging.operation.enabled'] = true
  site_xml['hive.server2.logging.operation.log.location'] =
    '/tmp/${user.name}/operation_logs'
  site_xml['hive.server2.logging.operation.verbose'] = true
  site_xml['hive.stats.autogather'] = true
  site_xml['hive.stats.dbclass'] = 'jdbc:mysql'
  site_xml['hive.stats.jdbcdriver'] = 'com.mysql.jdbc.Driver'
  site_xml['hive.support.concurrency'] = true
  site_xml['hive.warehouse.subdir.inherit.perms'] = true

  # All other prefixes
  site_xml['datanucleus.autoCreateSchema'] = false
  site_xml['datanucleus.fixedDatastore'] = true
  site_xml['javax.jdo.option.ConnectionUserName'] = "hive"
end

# These will become key/value pairs in 'hive-env.sh'
default[:bcpc][:hadoop][:hive][:env_sh].tap do |env_sh|
  env_sh[:HIVE_CONF_DIR] = '/etc/hive/conf.' + node.chef_environment
  env_sh[:HIVE_AUX_JARS_PATH] =
    '/usr/hdp/current/hive-webhcat/share/hcatalog/hive-hcatalog-core.jar'
  env_sh[:JAVA_HOME] = node[:bcpc][:hadoop][:java]
  env_sh[:HADOOP_HEAPSIZE] = 1024
  env_sh[:HADOOP_OPTS] = ' ' +
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
    '-XX:+CMSClassUnloadingEnabled ' +
    '-XX:+UseParNewGC'
  env_sh[:HIVE_LOG_DIR] = "/var/log/hive"
  env_sh[:HIVE_PID_DIR] = "/var/run/hive"
  env_sh[:HIVE_IDENT_STRING] = "hive"
end
