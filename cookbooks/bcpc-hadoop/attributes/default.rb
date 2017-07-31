###########################################
#
#  Hadoop specific configs
#
#############################################
require 'pathname'

default['bcpc']['hadoop'] = {}
default['bcpc']['hadoop']['distribution']['release'] = '2.6.1.17-1'
default['bcpc']['hadoop']['distribution']['active_release'] = node['bcpc']['hadoop']['distribution']['release']
default['bcpc']['hadoop']['decommission']['hosts'] = []
# disks to use for Hadoop activities (expected to be an environment or role set variable)
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
default['bcpc']['hadoop']['hdfs']['site_xml']['dfs.datanode.sync.behind.writes'] = true
default['bcpc']['hadoop']['hdfs']['site_xml']['dfs.datanode.synconclose'] = true
default['bcpc']['hadoop']['hdfs']['site_xml']['dfs.namenode.stale.datanode.interval'] = 30_000
default['bcpc']['hadoop']['hdfs']['HA'] = true
default['bcpc']['hadoop']['hdfs']['failed_volumes_tolerated'] = 1
default['bcpc']['hadoop']['hdfs']['dfs_replication_factor'] = 3
default['bcpc']['hadoop']['hdfs']['dfs_blocksize'] = '128m'
default['bcpc']['hadoop']['hdfs_url'] = "hdfs://#{node.chef_environment}"
default['bcpc']['hadoop']['jmx_enabled'] = true
default[:bcpc][:hadoop][:jute][:maxbuffer] = 6_291_456
default['bcpc']['hadoop']['datanode']['xmx']['max_size'] = 4_096
default['bcpc']['hadoop']['datanode']['xmx']['max_ratio'] = 0.25
default['bcpc']['hadoop']['datanode']['max']['xferthreads'] = 16_384

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
default['bcpc']['hadoop']['namenode']['handler']['count'] = 100
# set to nil to calculate dynamically based on available memory
default['bcpc']['hadoop']['namenode']['xmx']['max_size'] = 1024
# set to nil to calculate dynamically based on available memory
default['bcpc']['hadoop']['namenode']['xmn']['max_size'] = 128
default['bcpc']['hadoop']['namenode']['xmx']['max_ratio'] = 0.25
default['bcpc']['hadoop']['namenode']['rpc']['port'] = 8020
default['bcpc']['hadoop']['namenode']['http']['port'] = 50070
default['bcpc']['hadoop']['namenode']['https']['port'] = 50470
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
default[:bcpc][:hadoop][:nn_hosts] = []
default[:bcpc][:hadoop][:jn_hosts] = []
default[:bcpc][:hadoop][:rm_hosts] = []
default[:bcpc][:hadoop][:hs_hosts] = []
default[:bcpc][:hadoop][:dn_hosts] = []
default[:bcpc][:hadoop][:hb_hosts] = []
default[:bcpc][:hadoop][:hive_hosts] = []
default[:bcpc][:hadoop][:oozie_hosts] = []
default[:bcpc][:hadoop][:httpfs_hosts] = []
default[:bcpc][:hadoop][:httpfs_hosts] = []
default[:bcpc][:hadoop][:rs_hosts] = []
default[:bcpc][:hadoop][:mysql_hosts] = []

default['bcpc']['keepalived']['config_template'] = 'keepalived.conf_hadoop'

default['bcpc']['revelytix']['loom_username'] = 'loom'
default['bcpc']['revelytix']['activescan_hdfs_user'] = 'activescan-user'
default['bcpc']['revelytix']['activescan_hdfs_enabled'] = 'true'
default['bcpc']['revelytix']['activescan_table_enabled'] = 'true'
default['bcpc']['revelytix']['hdfs_scan_interval'] = 60
default['bcpc']['revelytix']['hdfs_parse_lines'] = 50
default['bcpc']['revelytix']['hdfs_score_threshold'] = 0.25
default['bcpc']['revelytix']['hdfs_max_buffer_size'] = 8_388_608
default['bcpc']['revelytix']['persist_mode'] = 'hive'
default['bcpc']['revelytix']['dataset_persist_dir'] = 'loom-datasets'
default['bcpc']['revelytix']['temporary_file_dir'] = 'hdfs-default:loom-temp'
default['bcpc']['revelytix']['job_service_thread_pool_size'] = 10
default['bcpc']['revelytix']['security_authentication'] = 'loom'
default['bcpc']['revelytix']['security_enabled'] = 'true'
default['bcpc']['revelytix']['ssl_enabled'] = 'true'
default['bcpc']['revelytix']['ssl_port'] = 8443
default['bcpc']['revelytix']['ssl_keystore'] = 'config/keystore'
default['bcpc']['revelytix']['ssl_key_password'] = ''
default['bcpc']['revelytix']['ssl_trust_store'] = 'config/truststore'
default['bcpc']['revelytix']['ssl_trust_password'] = ''
default['bcpc']['revelytix']['loom_dist_cache'] = 'loom-dist-cache'
default['bcpc']['revelytix']['hive_classloader_blacklist_jars'] = 'slf4j,log4j,commons-logging'
default['bcpc']['revelytix']['port'] = 8080

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
default['chef_client']['log_perm'] = 0o644

default['bcpc']['hadoop']['copylog']['syslog'] = {
  'logfile' => '/var/log/syslog',
  'docopy' => true
}

default['bcpc']['hadoop']['copylog']['authlog'] = {
  'logfile' => '/var/log/auth.log',
  'docopy' => true
}

# Ensure the following group mappings in the group database
default[:bcpc][:hadoop][:os][:group][:hadoop][:members] = %w(
  hdfs
  yarn
  hbase
  oozie
  hive
  zookeeper
  mapred
  httpfs
)

default[:bcpc][:hadoop][:os][:group][:hdfs][:members] = ['hdfs']
default[:bcpc][:hadoop][:os][:group][:mapred][:members] = ['yarn']

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

default['bcpc']['cluster']['file_path'] = '/home/vagrant/chef-bcpc/cluster.txt'
