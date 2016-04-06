default[:spark][:download][:url] = 'http://d3kbcqa49mib13.cloudfront.net'
default[:spark][:download][:file][:name] = 'spark-1.6.0-bin-hadoop2.6'
default[:spark][:download][:file][:type] = 'tgz'
default[:spark][:download][:dir] = '/home/vagrant/chef-bcpc/bins'
default[:spark][:package][:install_meta] = false
default[:spark][:package][:base] = '/usr/spark'
default[:spark][:package][:prefix] = 'spark'
default[:spark][:package][:version] = '1.6.0'
default[:spark][:hdfs_url] = node['bcpc']['hadoop']['hdfs_url']
default[:spark][:bin][:dir] = "#{node[:spark][:package][:base]}/#{node[:spark][:package][:version]}"


## Spark Configuration
default.bach_spark.config.spark.driver.extraLibraryPath = "/usr/hdp/current/hadoop-client/lib/native:/usr/hdp/current/hadoop-client/lib/native/Linux-amd64-64"
default.bach_spark.config.spark.executor.extraLibraryPath = "/usr/hdp/current/hadoop-client/lib/native:/usr/hdp/current/hadoop-client/lib/native/Linux-amd64-64"
default.bach_spark.spark.config.executor.extraJavaOptions = "-verbose:gc -XX:+PrintHeapAtGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintTenuringDistribution -XX:+UseNUMA -XX:+PrintGCApplicationStoppedTime -XX:+UseCompressedOops -XX:+PrintClassHistogram -XX:+PrintGCApplicationConcurrentTime"
default.bach_spark.config.spark.shuffle.consolidateFiles = true
default.bach_spark.config.spark.shuffle.io.numConnectionsPerPeer =  2
default.bach_spark.config.spark.history.fs.logDirectory = "#{node['spark']['hdfs_url']}/spark-history"
default.bach_spark.config.spark.eventLog.dir = "#{node['spark']['hdfs_url']}/spark-history" 
default.bach_spark.config.spark.eventLog.enabled = true
default.bach_spark.config.spark.logConf = true
default.bach_spark.config.spark.dynamicAllocation.enabled = true
default.bach_spark.config.spark.shuffle.service.enabled = true
default.bach_spark.config.spark.yarn.jar = "#{node['spark']['hdfs_url']}/apps/spark/#{node[:spark][:package][:version]}/spark-assembly.jar" 
default.bach_spark.config.spark.yarn.queue = "spark"
default.bach_spark.config.spark.master = "yarn-client"

# Spark environment configuration
default.bach_spark.environment.SPARK_LOCAL_IP = node.bcpc.floating.ip
default.bach_spark.environment.SPARK_PUBLIC_DNS = float_host(node['fqdn'])
default.bach_spark.environment.HADOOP_CONF_DIR = "/etc/hadoop/conf"
default.bach_spark.environment.HIVE_CONF_DIR = "/etc/hive/conf"
default.bach_spark.environment.SPARK_DIST_CLASSPATH = "${HIVE_CONF_DIR}:${SPARK_LIBRARY_PATH}:$(for i in $(export IFS=\":\"; for i in $(hadoop classpath); do find $i -maxdepth 1 -name \"*.jar\"; done | egrep -v \"jackson-databind-.*.jar|jackson-core.jar|jackson-core-.*.jar|jackson-annotations-.*.jar\"); do echo -n \"${i}:\"; done | sed 's/:$//')"
default.bach_spark.environment.SPARK_CLASSPATH = "$SPARK_DIST_CLASSPATH:$SPARK_CLASSPATH"
default.bach_spark.environment.SPARK_LOCAL_DIRS = "/home/$(whoami)/.spark_logs"
