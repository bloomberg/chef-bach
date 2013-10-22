
#############################################
#
#  Hadoop specific configs
#
#############################################

default[:bcpc][:hadoop] = {}
default[:bcpc][:zookeeper][:id] = 0
default[:bcpc][:namenode][:id] = -1
default[:bcpc]['repos']['cloudera'] = "http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh"
default[:bcpc][:hadoop][:disks] = []
default[:bcpc][:hadoop][:min_node_count] = 3
