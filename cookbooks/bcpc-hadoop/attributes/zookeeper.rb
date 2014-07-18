#######################################
#    Zookeeper specific attributes    # 
#######################################

# Data directory for Zookeeper state
default[:bcpc][:zookeeper][:data_dir] = '/var/lib/zookeeper'

# Log directory for Zookeeper state
default[:bcpc][:zookeeper][:log_dir] = '/var/log/zookeeper'

# Client port for ZooKeeper.
default[:bcpc][:zookeeper][:port] = 2181

# JMX port for ZooKeeper.
default[:bcpc][:zookeeper][:jmx_port] = 10113

#Limit on the number of connections
default[:bcpc][:zookeeper][:maxClientCnxns] = 500

# The number of milliseconds of each tick
default[:bcpc][:zookeeper][:tick_time] = 2000

# The number of ticks that the initial synchronization phase can take
default[:bcpc][:zookeeper][:init_limit] = 10

# The number of ticks that can pass between sending a request and getting an acknowledgement
default[:bcpc][:zookeeper][:sync_limit] = 5

# Zookeeper servers
default[:bcpc][:zookeeper][:servers] = []

#Zookeeper owner
default[:bcpc][:zookeeper][:owner] = 'zookeeper'

#ZooKeeper group
default[:bcpc][:zookeeper][:group] = 'zookeeper'
