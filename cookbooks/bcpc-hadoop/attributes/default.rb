###########################################
#
#  Hadoop specific configs
#
#############################################

default["bcpc"]["hadoop"] = {}
default["bcpc"]["hadoop"]["distribution"]["version"] = 'HDP'
default["bcpc"]["hadoop"]["distribution"]["key"] = 'hortonworks.key'
default["bcpc"]["hadoop"]["distribution"]["release"] = '2.3.4.0-3485'
default["bcpc"]["hadoop"]["distribution"]["active_release"] = node["bcpc"]["hadoop"]["distribution"]["release"]
# disks to use for Hadoop activities (expected to be an environment or role set variable)
default["bcpc"]["hadoop"]["hadoop_home_warn_suppress"] = 1
default["bcpc"]["hadoop"]["hadoop_log_dir"] = "/var/log/hadoop-hdfs"
default["bcpc"]["hadoop"]["hadoop_mapred_ident_string"] = "mapred"
default["bcpc"]["hadoop"]["hadoop_mapred_log_dir"] = "/var/log/hadoop-mapreduce"
default["bcpc"]["hadoop"]["hadoop_secure_dn_log_dir"] = "/var/log/hadoop-hdfs"
default["bcpc"]["hadoop"]["hadoop_pid_dir"] = "/var/run/hadoop-hdfs"
default["bcpc"]["hadoop"]["hadoop_secure_dn_pid_dir"] = "/var/run/hadoop-hdfs"
default["bcpc"]["hadoop"]["hadoop_mapred_pid_dir"] = "/var/run/hadoop-mapreduce"
default["bcpc"]["hadoop"]["hadoop_secure_dn_user"] = "hdfs"
default["bcpc"]["hadoop"]["hadoop"]["bin"]["path"] = "/usr/bin/hadoop"
default["bcpc"]["hadoop"]["hadoop"]["config"]["dir"] = "/etc/hadoop/conf"
default["bcpc"]["hadoop"]["hdfs"]["HA"] = true
default["bcpc"]["hadoop"]["hdfs"]["failed_volumes_tolerated"] = 1
default["bcpc"]["hadoop"]["hdfs"]["dfs_replication_factor"] = 3
default["bcpc"]["hadoop"]["hdfs"]["dfs_blocksize"] = "128m"
default['bcpc']['hadoop']['hdfs_url']="hdfs://#{node.chef_environment}"
default["bcpc"]["hadoop"]["jmx_enabled"] = true
default[:bcpc][:hadoop][:jute][:maxbuffer] = 6291456
default["bcpc"]["hadoop"]["datanode"]["xmx"]["max_size"] = 4096
default["bcpc"]["hadoop"]["datanode"]["xmx"]["max_ratio"] = 0.25
default["bcpc"]["hadoop"]["datanode"]["max"]["xferthreads"] = 16384
default["bcpc"]["hadoop"]["datanode"]["jmx"]["port"] = 10112
default["bcpc"]["hadoop"]["datanode"]["gc_opts"] = "-server -XX:ParallelGCThreads=4 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -verbose:gc -XX:+PrintHeapAtGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xloggc:/var/log/hadoop-hdfs/gc/gc.log-datanode-$$-$(hostname)-$(date +'%Y%m%d%H%M').log -XX:+PrintTenuringDistribution -XX:+UseNUMA -XX:+PrintGCApplicationStoppedTime -XX:+UseCompressedOops -XX:+PrintClassHistogram -XX:+PrintGCApplicationConcurrentTime"
default["bcpc"]["hadoop"]["mapreduce"]["framework"]["name"] = "yarn"
default["bcpc"]["hadoop"]["namenode"]["handler"]["count"] = 100
default["bcpc"]["hadoop"]["namenode"]["gc_opts"] = "-server -XX:ParallelGCThreads=14 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -verbose:gc -XX:+PrintHeapAtGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xloggc:/var/log/hadoop-hdfs/gc/gc.log-namenode-$$-$(hostname)-$(date +'%Y%m%d%H%M').log -XX:+PrintTenuringDistribution -XX:+UseNUMA -XX:+PrintGCApplicationStoppedTime -XX:+UseCompressedOops -XX:+PrintClassHistogram -XX:+PrintGCApplicationConcurrentTime"
default["bcpc"]["hadoop"]["namenode"]["xmx"]["max_size"] = 16384
default["bcpc"]["hadoop"]["namenode"]["xmx"]["max_ratio"] = 0.25
default["bcpc"]["hadoop"]["namenode"]["jmx"]["port"] = 10111
default["bcpc"]["hadoop"]["namenode"]["rpc"]["port"] = 8020
default["bcpc"]["hadoop"]["namenode"]["http"]["port"] = 50070 
default["bcpc"]["hadoop"]["namenode"]["https"]["port"] = 50470
default["bcpc"]["hadoop"]["kafka"]["jmx"]["port"] = 9995
default["bcpc"]["hadoop"]["topology"]["script"] = "topology"
default["bcpc"]["hadoop"]["topology"]["cookbook"] = "bcpc-hadoop"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["minimum-allocation-mb"] = 256

# Setting balancer bandwidth to default value as per hdfs-default.xml
default["bcpc"]["hadoop"]["balancer"]["bandwidth"] = 1048576

#
# Attributes for service rolling restart process
#
# Number of tries to acquire the lock required to restart the process
default["bcpc"]["hadoop"]["restart_lock_acquire"]["max_tries"] = 5
# The path in ZK where the restart locks (znodes)  need to be created
# The path should exist in ZooKeeper e.g. "/lock" and the default is "/"
default["bcpc"]["hadoop"]["restart_lock"]["root"] = "/"
# Sleep time in seconds between tries to acquire the lock for restart
default["bcpc"]["hadoop"]["restart_lock_acquire"]["sleep_time"] = 2
# Flag to set whether the restart process was successful or not
default["bcpc"]["hadoop"]["datanode"]["restart_failed"] = false

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

default["bcpc"]["keepalived"]["config_template"] = "keepalived.conf_hadoop"

default["bcpc"]["revelytix"]["loom_username"] = "loom"
default["bcpc"]["revelytix"]["activescan_hdfs_user"] = "activescan-user"
default["bcpc"]["revelytix"]["activescan_hdfs_enabled"] = "true"
default["bcpc"]["revelytix"]["activescan_table_enabled"] = "true"
default["bcpc"]["revelytix"]["hdfs_scan_interval"] = 60
default["bcpc"]["revelytix"]["hdfs_parse_lines"] = 50
default["bcpc"]["revelytix"]["hdfs_score_threshold"] = 0.25
default["bcpc"]["revelytix"]["hdfs_max_buffer_size"] = 8388608
default["bcpc"]["revelytix"]["persist_mode"] = "hive"
default["bcpc"]["revelytix"]["dataset_persist_dir"] = "loom-datasets"
default["bcpc"]["revelytix"]["temporary_file_dir"] = "hdfs-default:loom-temp"
default["bcpc"]["revelytix"]["job_service_thread_pool_size"] = 10
default["bcpc"]["revelytix"]["security_authentication"] = "loom"
default["bcpc"]["revelytix"]["security_enabled"] = "true"
default["bcpc"]["revelytix"]["ssl_enabled"] = "true"
default["bcpc"]["revelytix"]["ssl_port"] = 8443
default["bcpc"]["revelytix"]["ssl_keystore"] = "config/keystore"
default["bcpc"]["revelytix"]["ssl_key_password"] = ""
default["bcpc"]["revelytix"]["ssl_trust_store"] = "config/truststore"
default["bcpc"]["revelytix"]["ssl_trust_password"] = ""
default["bcpc"]["revelytix"]["loom_dist_cache"] = "loom-dist-cache"
default["bcpc"]["revelytix"]["hive_classloader_blacklist_jars"] = "slf4j,log4j,commons-logging"
default["bcpc"]["revelytix"]["port"] = 8080

# Attributes to store details about (log) files from nodes to be copied
# into a centralized location (currently HDFS).
# E.g. value {'hbase_rs' =>  { 'logfile' => "/path/file_name_of_log_file",
#                              'docopy' => true (or false)
#                             },...
#            }
# It is expected recipes will extend this value as they have files to ship
default['bcpc']['hadoop']['copylog'] = {}
# Attribute to enable/disable the copylog feature
default['bcpc']['hadoop']['copylog_enable'] = true
# File rollup interval in secs for log data copied into HDFS through Flume
default['bcpc']['hadoop']['copylog_rollup_interval'] = 86400

# Ensure the following group mappings in the group database
default[:bcpc][:hadoop][:os][:group][:hadoop][:members]=["hdfs","yarn"]
default[:bcpc][:hadoop][:os][:group][:hdfs][:members]=["hdfs"]
default[:bcpc][:hadoop][:os][:group][:mapred][:members]=["yarn"]

# Override defaults for the Java cookbook
default['java']['jdk_version'] = 7
default['java']['install_flavor'] = "oracle"
default['java']['accept_license_agreement'] = true
default['java']['jdk']['7']['x86_64']['url'] = get_binary_server_url + "jdk-7u51-linux-x64.tar.gz"
default['java']['jdk']['8']['x86_64']['url'] = get_binary_server_url + 'jdk-8u74-linux-x64.tar.gz'
default['java']['jdk']['8']['x86_64']['checksum'] = '0bfd5d79f776d448efc64cb47075a52618ef76aabb31fde21c5c1018683cdddd'
default['java']['oracle']['jce']['enabled'] = true
default['java']['oracle']['jce']['7']['url'] = get_binary_server_url + "UnlimitedJCEPolicyJDK7.zip"
default['java']['oracle']['jce']['8']['url'] = get_binary_server_url + "jce_policy-8.zip"

# Set the JAVA_HOME for Hadoop components
default['bcpc']['hadoop']['java'] = '/usr/lib/jvm/java-7-oracle-amd64'


default['bcpc']['cluster']['file_path'] = "/home/vagrant/chef-bcpc/cluster.txt"
