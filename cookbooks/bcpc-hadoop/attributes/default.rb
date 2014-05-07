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
default["bcpc"]["repos"]["hortonworks"] = 'http://public-repo-1.hortonworks.com/HDP/ubuntu12/2.x'
default["bcpc"]["repos"]["hdp_utils"] = 'http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.16/repos/ubuntu12'
default["bcpc"]["hadoop"]["disks"] = []
default["bcpc"]["hadoop"]["oozie"]["admins"] = []
default["bcpc"]["hadoop"]["hdfs"]["failed_volumes_tolerated"] = 1
default["bcpc"]["hadoop"]["hdfs"]["dfs_replication_factor"] = 3
default["bcpc"]["hadoop"]["jmx_enabled"] = false
default["bcpc"]["hadoop"]["jmx"]["port"]["namenode"] = 3010
default["bcpc"]["hadoop"]["jmx"]["port"]["datanode"] = 3010
default["bcpc"]["hadoop"]["jmx"]["port"]["hbase_master"] = 3010

default["bcpc"]["revelitix"]["loom-username"] = "loom"
default["bcpc"]["revelytix"]["activescan-hdfs-user"] = "activescan-user"
default["bcpc"]["revelytix"]["activescan-hdfs-enabled"] = "true"
default["bcpc"]["revelytix"]["activescan-table-enabled"] = "true"
default["bcpc"]["revelytix"]["hdfs-scan-interval"] = 60
default["bcpc"]["revelytix"]["hdfs-parse-lines"] = 50
default["bcpc"]["revelytix"]["hdfs-score-threshold"] = 0.25
default["bcpc"]["revelytix"]["hdfs-max-buffer-size"] = 8388608
default["bcpc"]["revelytix"]["persist-mode"] = "hive"
default["bcpc"]["revelytix"]["dataset-persist-dir"] = "loom-datasets"
default["bcpc"]["revelytix"]["temporary-file-dir"] = "hdfs-default:loom-temp"
default["bcpc"]["revelytix"]["job-service-threadpool-size"] = 10
default["bcpc"]["revelytix"]["security.authentication"] = "loom"
default["bcpc"]["revelytix"]["ssl-enabled"] = "true"
default["bcpc"]["revelytix"]["ssl-port"] = 8443
default["bcpc"]["revelytix"]["ssl-keystore"] = "config/keystore"
default["bcpc"]["revelytix"]["ssl-key-password"] = ""
default["bcpc"]["revelytix"]["ssl-trust-store"] = "config/truststore"
default["bcpc"]["revelytix"]["ssl-trust-password"] = ""
default["bcpc"]["revelytix"]["loom-dist-cache"] = "loom-dist-cache"
default["bcpc"]["revelytix"]["hive-classloader-blacklist-jars"] = "slf4j,log4j,commons-logging"
default["bcpc"]["revelytix"]["port"] = 8080

default["bcpc"]["keepalived"]["config_template"] = "keepalived.conf_hadoop"
