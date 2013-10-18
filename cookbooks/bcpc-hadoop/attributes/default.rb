
#############################################
#
#  Hadoop specific configs
#
#############################################

include_attribute "zookeeper"

default[:bpcp][:hadoop] = {}
default[:bcpc][:zookeeper][:id] = 0
default[:bcpc][:namenode][:id] = -1
default[:bcpc]['repos']['cloudera'] = "http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh"
default[:bcpc][:hadoop][:journal][:path] = "/disk1/dfs/jn"
