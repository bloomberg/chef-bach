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
