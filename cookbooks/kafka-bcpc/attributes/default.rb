#######################################
#    Kafka BCPC specific attributes   # 
#######################################

# Attribute to indidate whether an existing Hadoop Zookeeper
# can be used. If not Kafka Zookeeper quorum need to be created 
default[:use_hadoop_zookeeper_quorum] = false
#
# Overwriting community kafka cookbook attributes 
#
default[:kafka][:port] = 9092
default[:kafka][:advertised_port] = 9092
default[:kafka][:automatic_start] = true
default[:kafka][:automatic_restart] = true

