#######################################
#    Zookeeper specific attributes    #
#######################################

# Conf directory for Zookeeper
default[:bcpc][:hadoop][:zookeeper][:conf_dir] = '/etc/zookeeper/conf'

# Data directory for Zookeeper state
default[:bcpc][:hadoop][:zookeeper][:data_dir] = '/var/lib/zookeeper'

# Data log directory for Zookeeper state
default[:bcpc][:hadoop][:zookeeper][:data_log_dir] = '/var/lib/zookeeper'

# Log directory for Zookeeper state
default[:bcpc][:hadoop][:zookeeper][:log_dir] = '/var/log/zookeeper'

# Client port for ZooKeeper.
default[:bcpc][:hadoop][:zookeeper][:port] = 2181

# JMX port for ZooKeeper.
default[:bcpc][:hadoop][:zookeeper][:jmx][:port] = 10_113

# Limit on the number of connections
default[:bcpc][:hadoop][:zookeeper][:maxClientCnxns] = 500

# The number of milliseconds of each tick
default[:bcpc][:hadoop][:zookeeper][:tick_time] = 2000

# The number of ticks that the initial synchronization phase can take
default[:bcpc][:hadoop][:zookeeper][:init_limit] = 10

# The number of ticks that can pass between sending a request and
# getting an acknowledgement
default[:bcpc][:hadoop][:zookeeper][:sync_limit] = 5

# Zookeeper servers
default[:bcpc][:hadoop][:zookeeper][:servers] = []

# Zookeeper owner
default[:bcpc][:hadoop][:zookeeper][:owner] = 'zookeeper'

# ZooKeeper group
default[:bcpc][:hadoop][:zookeeper][:group] = 'zookeeper'

# Port to connect to the leader in the Quorum
default[:bcpc][:hadoop][:zookeeper][:leader_connect][:port] = 2888

# Port for leader election in the Quorum
default[:bcpc][:hadoop][:zookeeper][:leader_elect][:port] = 3888

# Number of ZooKeeper snapshots to be retained
default[:bcpc][:hadoop][:zookeeper][:snap][:retain_count] = 5

# ZooKeeper snapshot purge interval in hours
default[:bcpc][:hadoop][:zookeeper][:snap][:purge_interval] = 24

# ZooKeeper memory controls
default['bcpc']['hadoop']['zookeeper']['xmx']['max_size'] = 4_096
default['bcpc']['hadoop']['zookeeper']['xmx']['max_ratio'] = 0.10

common_opts =
  '-XX:+UseGCLogFileRotation ' \
  '-XX:GCLogFileSize=20M ' \
  '-XX:NumberOfGCLogFiles=20 ' \
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
  '-XX:+HeapDumpOnOutOfMemoryError ' \
  '-XX:+PrintTenuringDistribution ' \
  '-XX:+ExitOnOutOfMemoryError ' \
  "-agentpath:#{node['bcpc-hadoop']['jvmkill']['lib_file']}"

# GC Options for DataNode
default['bcpc']['hadoop']['zookeeper']['gc_opts'] =
  '-server -XX:ParallelGCThreads=4 ' \
  '-XX:CMSInitiatingOccupancyFraction=70 ' \
  '-Xloggc:/var/log/zookeeper/gc/gc.log-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log ' \
  '-XX:HeapDumpPath=/var/log/zookeeper/heap-dump-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof ' +
  common_opts
