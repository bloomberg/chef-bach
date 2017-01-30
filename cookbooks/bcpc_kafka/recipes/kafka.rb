#
# Cookbook Name:: bcpc_kafka
# Recipe: Kafka
#

#
# We need node search to set a reasonable value for num.partitions, so
# the value from the attributes file must be overriden.
#
# The value is saved in the node object so that the default partition count
# can only go up, not down.
#
node.normal[:kafka][:broker][:num][:partitions] =
  [
   node[:kafka][:broker][:num][:partitions],
   search(:node, 'role:BCPC-Kafka-Head-Server').count,
   3
  ].max

package 'netcat-openbsd'

zookeeper_port =
  node[:bcpc][:hadoop][:zookeeper][:leader_connect][:port] rescue 2181

#
# In a standalone Kafka cluster, get_head_nodes will return the
# Zookeeper servers.
#
# In a mixed Hadoop/Kafka cluster, the regular Hadoop head nodes will
# be running Zookeeper.
#
# See cookbooks/bcpc/libraries/utils.rb for details.
#
node.default[:kafka][:broker][:zookeeper][:connect] = get_head_nodes.map do |nn|
  float_host(nn[:fqdn])
end

#
# This is a list of paths for the kafka logs (actual topic data)
#
# The path for human-readable logs (information about what kafka is
# doing) is found in node[:kafka][:log_dir]
#
# Unfortunately this cannot be a lazy block (Chef::DelayedEvaluator)
# because the upstream kafka cookbook expects to examine log directory
# values at compile time.
#
# As a result, the first chef run will configure Kafka to use only one
# data volume, the fallback path of /disk/0.
#
data_volumes = Dir.glob('/disk/*').select{ |pp| ::File.directory?(pp) }

if data_volumes.empty?
  data_volumes << '/disk/0'
end

node.default[:kafka][:broker][:log][:dirs] = data_volumes.map do |dd|
  File.join(dd, 'kafka', 'data')
end

include_recipe 'bcpc_kafka::default'
include_recipe 'kafka::default'

user_ulimit "kafka" do
  filehandle_limit 32768
  notifies :restart, "service[kafka-broker]", :immediately
end

ruby_block "kafkaup" do
  i = 0
  block do
    brokerpath="/brokers/ids/#{node[:kafka][:broker][:broker_id]}"
    zk_host = node[:kafka][:broker][:zookeeper][:connect].map{|zkh| "#{zkh}:2181"}.join(",")
    Chef::Log.info("Zookeeper hosts are #{zk_host}")
    sleep_time = 0.5
    kafka_in_zk = znode_exists?(brokerpath, zk_host)
    while !kafka_in_zk
      kafka_in_zk = znode_exists?(brokerpath, zk_host)
      if !kafka_in_zk and i < 20
        sleep(sleep_time)
        i += 1
        Chef::Log.info("Kafka server having znode #{brokerpath} is down.")
      elsif !kafka_in_zk and i >= 19
        Chef::Application.fatal! "Kafka is reported down for more than #{i * sleep_time} seconds"
      else
        Chef::Log.info("Broker #{brokerpath} existance : #{znode_exists?(brokerpath, zk_host)}")
      end
    end
    Chef::Log.info("Kafka with znode #{brokerpath} is up and running.")
  end
  action :run
end

include_recipe 'bcpc::diamond'
include_recipe 'bcpc_jmxtrans'
