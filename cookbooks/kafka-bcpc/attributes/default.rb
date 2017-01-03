#######################################
#    Kafka BCPC specific attributes   #
#######################################

#
# Attribute to indidate whether an existing Hadoop Zookeeper
# can be used. If not Kafka Zookeeper quorum need to be created
#
# This should always be false.
#
default[:use_hadoop_zookeeper_quorum] = false

#
# Overwriting community kafka cookbook attributes
#
default[:kafka][:broker][:port] = 6667
default[:kafka][:broker][:advertised_port] = 6667
default[:kafka][:broker][:broker_id] = node[:bcpc][:node_number]
default[:kafka][:broker][:reserved_broker_max_id] = (2 ** 31) - 1
default[:kafka][:automatic_start] = true
default[:kafka][:automatic_restart] = true

default[:kafka][:base_url] = get_binary_server_url + 'kafka'
default[:kafka][:broker][:host_name] = float_host(node[:fqdn])
default[:kafka][:broker][:advertised_host_name] = float_host(node[:fqdn])
default[:kafka][:jmx_port] = node[:bcpc][:hadoop][:kafka][:jmx][:port]
default[:kafka][:broker][:controlled][:shutdown][:enable] = true
default[:kafka][:broker][:controlled][:shutdown][:max][:retries] = 3
default[:kafka][:broker][:controlled][:shutdown][:retry][:backoff][:ms] = 5000

#
# These attributes are normally overriden in the Chef environment.
#
default[:kafka][:version] = '0.9.0.1'
default[:kafka][:scala_version] = '2.11'

default[:kafka][:checksum] =
  'db28f4d5a9327711013c26632baed8e905ce2f304df89a345f25a6dfca966c7a'

default[:kafka][:md5_checksum] = ''
default[:kafka][:log_dir] = '/var/log/kafka'
