#######################################
#    Kafka BCPC specific attributes   #
#######################################

#
# Attribute to indidate whether an existing Hadoop Zookeeper
# can be used. If not Kafka Zookeeper quorum need to be created.
#
# This should always be false in a standalone Kafka cluster.
#
default[:use_hadoop_zookeeper_quorum] = false

#
# Overwriting community kafka cookbook attributes
#
default[:kafka][:automatic_start] = true
default[:kafka][:automatic_restart] = true
default[:kafka][:jmx_port] = node[:bcpc][:hadoop][:kafka][:jmx][:port]
default[:kafka][:zookeeper_connect] = nil

#
# ZooKeeper znode in the format /chroot to be used for the Kafka broker
#
default[:kafka][:root_znode] = nil

#
# Mapping of Kafka broker servers in a cluster to a rack id
# e.g. {'bcpc-vm1' => 'rack1', 'bcpc-vm2' => 'rack2' ...}
#
default[:kafka][:node_rack_map] = {}

#
# Kafka broker settings
#
default[:kafka][:broker].tap do |broker|
  broker[:host_name] = node[:fqdn]
  broker[:broker_id] = node[:bcpc][:node_number]
  broker[:reserved_broker_max_id] = (2 ** 31) - 1
  broker[:controlled][:shutdown][:enable] = true
  broker[:controlled][:shutdown][:max][:retries] = 3
  broker[:controlled][:shutdown][:retry][:backoff][:ms] = 5000
  broker[:unclean][:leader][:election][:enable] = false
  broker[:compression][:type] = 'lz4'
  broker[:auto][:create][:topics][:enable] = false
  broker[:num][:insync][:replicas] = 2
  broker[:max][:connections][:per][:ip] = 500

  # Migrate any 0.8.x nodes/topics to use Kafka-based offset storage.
  broker[:dual][:commit][:enabled] = false
  broker[:offsets][:storage] = 'kafka'

  # Default to a 1.1.0 protocol.
  broker[:inter][:broker][:protocol][:version] = '1.1.0'
  broker[:log][:message][:format][:version] = '1.1.0'

  # Defaults for new topics
  broker[:num][:partitions] = 3
  broker[:default][:replication][:factor] = 3

  #
  # This value was chosen arbitrarily.  Kafka defaults to 1 replica
  # fetcher thread, which is clearly too few.  But how many is too
  # many?
  #
  broker[:num][:replica][:fetchers] = 8

  # Kerberos config.
  broker[:sasl][:kerberos][:service][:name] = 'kafka'
  broker[:authorizor][:class][:name]='kafka.security.auth.SimpleAclAuthorizer'
  broker[:allow][:everyone][:if][:no][:acl][:found] = true
  broker[:super][:users] = 'kafka'

  #
  # We default to using PLAINTEXT for inter-broker communication, then
  # migrate to SASL after the cluster is up.
  #
  broker[:security][:inter][:broker][:protocol] = 'PLAINTEXT'

  #
  # Deprecated values used to generate listeners in the past.  Still
  # required by the upstream cookbook, but largely ignored by Kafka itself.
  #
  broker[:advertised_host_name] = node[:fqdn] # Deprecated.
  broker[:port] = 6667 # Deprecated.
  broker[:advertised_port] = 6667 # Deprecated.

  #
  # A more useful set of listeners.
  #
  # 6667 has no authentication.
  # 6668 is authenticated, but lacks SSL.
  #
  broker[:listeners] =
    "PLAINTEXT://#{float_host(node[:fqdn])}:6667," \
    "SASL_PLAINTEXT://#{float_host(node[:fqdn])}:6668"
end

#
# These attributes are normally overriden in the Chef environment.
#
default[:kafka][:version] = '1.1.1'
default[:kafka][:scala_version] = '2.11'

default[:kafka][:checksum] =
  '93b6f926b10b3ba826266272e3bd9d0fe8b33046da9a2688c58d403eb0a43430'

default[:kafka][:md5_checksum] = ''

#
# This is the path to human-readable log files, not kafka log data.
# (/disk/0 is a mount point created by the bcpc-hadoop::disks recipe)
#
default[:kafka][:log_dir] = '/disk/0/kafka/logs'

#
# Kafka GC log settings
#
default['kafka']['gc_log_opts'] = %W[
  -Xloggc:#{::File.join(node['kafka']['log_dir'], 'kafka-gc-pid-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log')}
  -XX:+UseGCLogFileRotation
  -XX:NumberOfGCLogFiles=20
  -XX:GCLogFileSize=20M
  -XX:+PrintGCDateStamps
  -XX:+PrintGCTimeStamps
].join(' ')
