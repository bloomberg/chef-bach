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

default[:kafka][:base_url] = get_binary_server_url + "kafka"
default[:kafka][:broker][:host_name] = float_host(node[:fqdn])
default[:kafka][:broker][:advertised_host_name] = float_host(node[:fqdn])
default[:kafka][:jmx_port] = node[:bcpc][:hadoop][:kafka][:jmx][:port]
default[:kafka][:broker][:controlled][:shutdown][:enable] = true
default[:kafka][:broker][:controlled][:shutdown][:max][:retries] = 3
default[:kafka][:broker][:controlled][:shutdown][:retry][:backoff][:ms] = 5000
