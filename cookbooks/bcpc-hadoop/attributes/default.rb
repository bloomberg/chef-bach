############################################
#
#  Hadoop specific configs
#
############################################
require 'pathname'


user = node['bcpc']['bootstrap']['admin']['user']
default['bcpc']['cluster']['file_path'] = "/home/#{user}/chef-bcpc/cluster.txt"

default['bcpc']['hadoop'] = {}
default['bcpc']['hadoop']['proxyuser']['ambari'] = 'ambariqa'
default['bcpc']['hadoop']['distribution']['release'] = '2.6.5.0-292'
default['bcpc']['hadoop']['distribution']['active_release'] = \
  node['bcpc']['hadoop']['distribution']['release']

default['bcpc']['hadoop']['decommission']['hosts'] = []
default['bcpc']['hadoop']['hadoop_home_warn_suppress'] = 1
default['bcpc']['hadoop']['hadoop_log_dir'] = '/var/log/hadoop-hdfs'
default['bcpc']['hadoop']['hadoop_mapred_ident_string'] = 'mapred'
default['bcpc']['hadoop']['hadoop_mapred_log_dir'] = '/var/log/hadoop-mapreduce'
default['bcpc']['hadoop']['hadoop_secure_dn_log_dir'] = '/var/log/hadoop-hdfs'
default['bcpc']['hadoop']['hadoop_pid_dir'] = '/var/run/hadoop-hdfs'
default['bcpc']['hadoop']['hadoop_secure_dn_pid_dir'] = '/var/run/hadoop-hdfs'
default['bcpc']['hadoop']['hadoop_mapred_pid_dir'] = '/var/run/hadoop-mapreduce'
default['bcpc']['hadoop']['hadoop_secure_dn_user'] = 'hdfs'
default['bcpc']['hadoop']['hadoop']['bin']['path'] = '/usr/bin/hadoop'
default['bcpc']['hadoop']['hadoop']['config']['dir'] = '/etc/hadoop/conf'

# Flag to control whether automatic restarts due to config changes need to be skipped
# for e.g. if ZK quorum is down or if the recipes need to be run in a non ZK env
default['bcpc']['hadoop']['skip_restart_coordination'] = false
default['bcpc']['hadoop']['hdfs']['HA'] = true
default['bcpc']['hadoop']['hdfs']['failed_volumes_tolerated'] = 1
default['bcpc']['hadoop']['hdfs']['dfs_replication_factor'] = 3
default['bcpc']['hadoop']['hdfs']['dfs_blocksize'] = '128m'
default['bcpc']['hadoop']['hdfs_url'] = "hdfs://#{node.chef_environment}"
default['bcpc']['hadoop']['jmx_enabled'] = false
default['bcpc']['hadoop']['jmx_agent_enabled'] = true




# for jvmkill library
default['bcpc-hadoop']['jvmkill']['lib_file'] = '/var/lib/jvmkill/libjvmkill.so'

common_opts =
  '-XX:+UseParNewGC ' \
  '-XX:+UseConcMarkSweepGC ' \
  '-verbose:gc -XX:+PrintHeapAtGC ' \
  '-XX:+PrintGCDetails ' \
  '-XX:+PrintGCTimeStamps ' \
  '-XX:+PrintGCDateStamps ' \
  '-XX:+UseNUMA ' \
  '-XX:+PrintGCApplicationStoppedTime ' \
  '-XX:+UseCompressedOops ' \
  '-XX:+PrintClassHistogram ' \
  '-XX:+PrintGCApplicationConcurrentTime ' \
  '-XX:+UseCMSInitiatingOccupancyOnly ' \
  '-XX:CMSInitiatingOccupancyFraction=70 ' \
  '-XX:+HeapDumpOnOutOfMemoryError ' \
  '-XX:+PrintTenuringDistribution ' \
  '-XX:+ExitOnOutOfMemoryError ' \
  "-agentpath:#{node['bcpc-hadoop']['jvmkill']['lib_file']}"

# GC Options for DataNode
default['bcpc']['hadoop']['datanode']['gc_opts'] =
  '-server -XX:ParallelGCThreads=4 ' \
  '-Xloggc:/var/log/hadoop-hdfs/gc/gc.log-dn-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log ' \
  '-XX:HeapDumpPath=/var/log/hadoop-hdfs/heap-dump-dn-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof ' +
  common_opts

# GC Options for NameNode
default['bcpc']['hadoop']['namenode']['gc_opts'] =
  '-server -XX:ParallelGCThreads=14 ' \
  '-Xloggc:/var/log/hadoop-hdfs/gc/gc.log-nn-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log ' \
  '-XX:HeapDumpPath=/var/log/hadoop-hdfs/heap-dump-nn-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof ' +
  common_opts

default['bcpc']['hadoop']['mapreduce']['framework']['name'] = 'yarn'
default['bcpc']['hadoop']['kafka']['jmx']['port'] = 9995
default['bcpc']['hadoop']['topology']['script'] = 'topology'
default['bcpc']['hadoop']['topology']['cookbook'] = 'bcpc-hadoop'
default['bcpc']['hadoop']['yarn']['scheduler']['minimum-allocation-mb'] = 256

#
# Attributes for service rolling restart process
#
# Number of tries to acquire the lock required to restart the process
default['bcpc']['hadoop']['restart_lock_acquire']['max_tries'] = 5
# The path in ZK where the restart locks (znodes)  need to be created
# The path should exist in ZooKeeper e.g. '/lock' and the default is '/'
default['bcpc']['hadoop']['restart_lock']['root'] = '/'
# Sleep time in seconds between tries to acquire the lock for restart
default['bcpc']['hadoop']['restart_lock_acquire']['sleep_time'] = 2
# Flag to set whether the restart process was successful or not
default['bcpc']['hadoop']['datanode']['restart_failed'] = false

# These are to cache Chef search results and
# allow hardcoding nodes performing various roles
default['bcpc']['hadoop']['nn_hosts'] = []
default['bcpc']['hadoop']['jn_hosts'] = []
default['bcpc']['hadoop']['rm_hosts'] = []
default['bcpc']['hadoop']['hs_hosts'] = []
default['bcpc']['hadoop']['dn_hosts'] = []
default['bcpc']['hadoop']['hb_hosts'] = []
default['bcpc']['hadoop']['hive_hosts'] = []
default['bcpc']['hadoop']['oozie_hosts'] = []
default['bcpc']['hadoop']['httpfs_hosts'] = []
default['bcpc']['hadoop']['rs_hosts'] = []
default['bcpc']['hadoop']['mysql_hosts'] = []

# logical mapping of services to runlist details.
default['bcpc']['hadoop']['services'] = {
  zookeeper: {
    key: [:zookeeper, :servers],
    role: 'role[BCPC-Hadoop-Head]',
  },
  journal_node: {
    key: :jn_hosts,
    role: 'role[BCPC-Hadoop-Head]',
  },

  resource_manager: {
    key: :rm_hosts,
    role: 'role[BCPC-Hadoop-Head-ResourceManager]',
  },
  job_history_server: {
    key: :jh_hosts,
    role: 'role[BCPC-Hadoop-Head-MapReduce]',
  },

  oozie_server: {
    key: :oozie_hosts,
    role: 'role[BCPC-Hadoop-Head-MapReduce]',
    recipe: 'recipe[bcpc-hadoop::oozie]',
  },
  mysql: {
    key: :mysql_hosts,
    role: 'role[BCPC-Hadoop-Head]',
  },

  hadoop_datanode: {
    key: :dn_hosts,
    role: 'role[BCPC-Hadoop-Worker]', 
  },

  hbase_master: {
    key: :hb_hosts,
    role: 'role[BCPC-Hadoop-Head-HBase]',
  },
  hbase_regionserver: {
    key: :rs_hosts,
    role: 'role[BCPC-Hadoop-Worker]',
  },

  hive_server: {
    key: :hive_hosts,
    role: 'role[BCPC-Hadoop-Head-Hive]',
  },

  httpfs_server: {
    key: :httpfs_hosts,
    role: 'role[BCPC-Hadoop-Worker]',
  },
}

default['bcpc']['keepalived']['config_template'] = 'keepalived.conf_hadoop'

# Attributes to store details about (log) files from nodes to be copied
# into a centralized location (currently HDFS).
# E.g. value {'hbase_rs' =>  { 'logfile' => '/path/file_name_of_log_file',
#                              'docopy' => true (or false)
#                             },...
#            }
# It is expected recipes will extend this value as they have files to ship
default['bcpc']['hadoop']['copylog'] = {}
# Attribute to enable/disable the copylog feature
default['bcpc']['hadoop']['copylog_enable'] = true
# HDFS quotas for copylogs files
default['bcpc']['hadoop']['copylog_quota'] = {
  'space' => '10G',
  'files' => 10_000
}
# File rollup interval in secs for log data copied into HDFS through Flume
default['bcpc']['hadoop']['copylog_rollup_interval'] = 86_400
# Ensure copylogs can read Chef's client.log
default['chef_client']['log_perm'] = 0o0644

default['bcpc']['hadoop']['copylog']['syslog'] = {
  'logfile' => '/var/log/syslog',
  'docopy' => true
}

default['bcpc']['hadoop']['copylog']['authlog'] = {
  'logfile' => '/var/log/auth.log',
  'docopy' => true
}

# Ensure the following group mappings in the group database
default['bcpc']['hadoop']['os']['group']['hadoop']['members'] = %w(
  hdfs
  yarn
  hbase
  oozie
  hive
  zookeeper
  mapred
  httpfs
)
default['bcpc']['hadoop']['os']['group']['hdfs']['members'] = ['hdfs']
default['bcpc']['hadoop']['os']['group']['mapred']['members'] = ['yarn']

# Override attributes to install Java
# use java cookbook (https://github.com/agileorbit-cookbooks/java)
default['java']['jdk_version'] = 8
default['java']['install_flavor'] = 'oracle'
default['java']['accept_license_agreement'] = true
default['java']['oracle']['jce']['enabled'] = true

# redirect the installation URLs to the bootstrap node
jdk_url = node['java']['jdk']['8']['x86_64']['url']
jce_url = node['java']['oracle']['jce']['8']['url']

jdk_tgz_name = Pathname.new(jdk_url).basename.to_s
jce_tgz_name = Pathname.new(jce_url).basename.to_s

default['java']['jdk']['8']['x86_64']['url'] = get_binary_server_url + jdk_tgz_name
default['java']['oracle']['jce']['8']['url'] = get_binary_server_url + jce_tgz_name

# Set the JAVA_HOME for Hadoop components
default['bcpc']['hadoop']['java'] = '/usr/lib/jvm/java-8-oracle-amd64'

# See bcpc-hadoop::ssl_configuration
default['bcpc']['hadoop']['java_ssl']['keystore'] = '/etc/bach/tls/keystore'
default['bcpc']['hadoop']['java_ssl']['password'] = 'changeit'
