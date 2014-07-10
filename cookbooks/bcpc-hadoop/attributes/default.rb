#############################################
#
#  Hadoop specific configs
#
#############################################

default["bcpc"]["hadoop"] = {}
default["bcpc"]["zookeeper"]["id"] = 0
default["bcpc"]["namenode"]["id"] = -1
default["bcpc"]["hadoop"]["distribution"]["version"] = 'HDP'
default["bcpc"]["hadoop"]["distribution"]["key"] = 'hortonworks.key'
default["bcpc"]["repos"]["hortonworks"] = 'http://public-repo-1.hortonworks.com/HDP/ubuntu12/2.0.11.0'
default["bcpc"]["repos"]["hdp_utils"] = 'http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.16/repos/ubuntu12'
default["bcpc"]["hadoop"]["disks"] = []
default["bcpc"]["hadoop"]["oozie"]["admins"] = []
default["bcpc"]["hadoop"]["hdfs"]["HA"] = false
default["bcpc"]["hadoop"]["hdfs"]["failed_volumes_tolerated"] = 1
default["bcpc"]["hadoop"]["hdfs"]["dfs_replication_factor"] = 3
default["bcpc"]["hadoop"]["jmx_enabled"] = true
default["bcpc"]["hadoop"]["namenode"]["jmx"]["port"] = 10111
default["bcpc"]["hadoop"]["datanode"]["jmx"]["port"] = 10112
default["bcpc"]["hadoop"]["hbase_master"]["jmx"]["port"] = 10101
default["bcpc"]["hadoop"]["hbase_rs"]["jmx"]["port"] = 10102
default["bcpc"]["hadoop"]["kafka"]["jmx"]["port"] = 9995
default["bcpc"]["hadoop"]["zookeeper"]["jmx"]["port"] = 10113

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

