default[:bach][:hive][:metastore][:port] = 9083
default[:bach][:hive][:hiveserver2][:port] = 10000
default[:bcpc][:hive][:heap][:size]=1024
default[:bcpc][:hive][:gc_opts] = " -verbose:gc -XX:+PrintHeapAtGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Xloggc:/var/log/hive/gc/gc.log-$$-$(hostname)-$(date +'%Y%m%d%H%M').log -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime"
