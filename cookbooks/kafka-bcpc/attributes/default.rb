#######################################
#    Kafka BCPC specific attributes   # 
#######################################

# Attribute to indidate whether an existing Hadoop Zookeeper
# can be used. If not Kafka Zookeeper quorum need to be created 
default[:use_hadoop_zookeeper_quorum] = false
