#######################################
#    Zookeeper specific attributes    # 
#######################################

# Data directory for Zookeeper state
default[:bcpc][:hadoop][:zookeeper][:data_dir] = '/var/lib/zookeeper'

# Log directory for Zookeeper state
default[:bcpc][:hadoop][:zookeeper][:log_dir] = '/var/log/zookeeper'

# Client port for ZooKeeper.
default[:bcpc][:hadoop][:zookeeper][:port] = 2181

# JMX port for ZooKeeper.
default[:bcpc][:hadoop][:zookeeper][:jmx][:port] = 10113

#Limit on the number of connections
default[:bcpc][:hadoop][:zookeeper][:maxClientCnxns] = 500

# The number of milliseconds of each tick
default[:bcpc][:hadoop][:zookeeper][:tick_time] = 2000

# The number of ticks that the initial synchronization phase can take
default[:bcpc][:hadoop][:zookeeper][:init_limit] = 10

# The number of ticks that can pass between sending a request and getting an acknowledgement
default[:bcpc][:hadoop][:zookeeper][:sync_limit] = 5

# Zookeeper servers
default[:bcpc][:hadoop][:zookeeper][:servers] = []

#Zookeeper owner
default[:bcpc][:hadoop][:zookeeper][:owner] = 'zookeeper'

#ZooKeeper group
default[:bcpc][:hadoop][:zookeeper][:group] = 'zookeeper'

#Port to connect to the leader in the Quorum
default[:bcpc][:hadoop][:zookeeper][:leader_connect][:port] = 2888

#Port for leader election in the Quorum
default[:bcpc][:hadoop][:zookeeper][:leader_elect][:port] = 3888
