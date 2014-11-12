#######################################
#    Kafka BCPC specific attributes   # 
#######################################

# Attribute to indidate whether an existing Hadoop Zookeeper
# can be used. If not Kafka Zookeeper quorum need to be created 
default[:use_hadoop_zookeeper_quorum] = false
#
# Overwriting community kafka cookbook attributes 
#
default[:kafka][:broker][:port] = 6667
default[:kafka][:broker][:advertised_port] = 6667
default[:kafka][:automatic_start] = true
default[:kafka][:automatic_restart] = true

