default['spark']['hdfs_url'] = node['bcpc']['hadoop']['hdfs_url']
default['spark']['bin']['dir'] = '/usr/hdp/current/spark2-client'
default['spark']['conf']['dir'] = '/etc/spark2/conf'

## Spark Configuration
default['bach_spark']['config'].tap do |spark_defaults|
  spark_defaults['spark.driver.extraLibraryPath'] = '/usr/hdp/current'\
    '/hadoop-client/lib/native:/usr/hdp/current'\
    '/hadoop-client/lib/native/Linux-amd64-64'
  spark_defaults['spark.executor.extraLibraryPath'] = '/usr/hdp/current'\
    '/hadoop-client/lib/native:/usr/hdp/current/hadoop-client/lib'\
    '/native/Linux-amd64-64'
  spark_defaults['spark.executor.extraJavaOptions'] =
    '-verbose:gc -XX:+PrintHeapAtGC -XX:+PrintGCDetails '\
    '-XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps '\
    '-XX:+PrintTenuringDistribution -XX:+UseNUMA '\
    '-XX:+PrintGCApplicationStoppedTime -XX:+UseCompressedOops '\
    '-XX:+PrintClassHistogram -XX:+PrintGCApplicationConcurrentTime'
  spark_defaults['spark.shuffle.consolidateFiles'] = true
  spark_defaults['spark.shuffle.io.numConnectionsPerPeer'] = 2
  spark_defaults['spark.history.fs.logDirectory'] =
    "#{node['spark']['hdfs_url']}/spark-history"
  spark_defaults['spark.eventLog.dir'] =
    "#{node['spark']['hdfs_url']}/spark-history"
  spark_defaults['spark.eventLog.enabled'] = true
  spark_defaults['spark.logConf'] = true
  spark_defaults['spark.dynamicAllocation.enabled'] = true
  spark_defaults['spark.shuffle.service.enabled'] = true
  spark_defaults['spark.yarn.archive'] = "#{node['spark']['hdfs_url']}"\
    '/apps/spark/'\
    "#{node['bcpc']['hadoop']['distribution']['active_release']}"\
    '/spark_jars.tgz'
  spark_defaults['spark.master'] = 'yarn-client'
end

# Spark environment configuration
default['bach_spark']['environment'].tap do |spark_env|
  spark_env['SPARK_LOCAL_IP'] = node[:ipaddress]
  spark_env['SPARK_PUBLIC_DNS'] = node[:fqdn]
  spark_env['SPARK_LOCAL_DIRS'] = '${HOME}/.spark_logs'
  spark_env['HADOOP_CONF_DIR'] = '/etc/hadoop/conf'
  spark_env['HADOOP_HOME'] = '/usr/hdp'\
    "/#{node['bcpc']['hadoop']['distribution']['active_release']}/hadoop"
  spark_env['HIVE_CONF_DIR'] = '/etc/hive/conf'
  spark_env['SPARK_DIST_CLASSPATH'] =
    '${HIVE_CONF_DIR}:${SPARK_LIBRARY_PATH}:$(for i in $(export IFS=":"; '\
    'for i in $(hadoop classpath); do find $i -maxdepth 1 -name "*.jar"; '\
    'done | egrep -v "jackson-databind-.*.jar|jackson-core.jar|'\
    'jackson-core-.*.jar|jackson-annotations-.*.jar"); '\
    "do echo -n \"${i}:\"; done | sed 's/:$//')"
  spark_env['SPARK_CLASSPATH'] =
    '$SPARK_DIST_CLASSPATH:$SPARK_CLASSPATH'
  spark_env['LD_LIBRARY_PATH'] = '/usr/hdp/current'\
    '/hadoop-client/lib/native:/usr/hdp/current'\
    '/hadoop-client/lib/native/Linux-amd64-64:$LD_LIBRARY_PATH'
end
