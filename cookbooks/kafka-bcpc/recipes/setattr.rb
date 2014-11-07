#
# Cookbook Name:: kafka-bcpc
# Recipe: setattr

# Override JAVA related node attributee
node.override['java']['jdk_version'] = '7'
node.override['java']['jdk']['7']['x86_64']['url'] = get_binary_server_url + "jdk-7u51-linux-x64.tar.gz"
node.override['java']['jdk']['7']['i586']['url'] = get_binary_server_url + "jdk-7u51-linux-i586.tar.gz"

# Get Kafka ZooKeeper servers
# Override ZooKeeper related node attribute if Kafka specific ZooKeeper quorum is used
if node[:use_hadoop_zookeeper_quorum]
  zk_hosts = node[:bcpc][:hadoop][:zookeeper][:servers]
else
  zk_hosts = get_req_node_attributes(get_zk_nodes,HOSTNAME_NODENO_ATTR_SRCH_KEYS)
  node.override[:bcpc][:hadoop][:zookeeper][:servers] = zk_hosts
end
# Override Kafka related node attributes
node.override[:kafka][:broker][:zookeeper][:connect] = zk_hosts.map{|x| float_host(x['hostname'])}
node.override[:kafka][:base_url] = get_binary_server_url + "kafka"
node.override[:kafka][:broker][:host_name] = float_host(node[:fqdn])
node.override[:kafka][:broker][:advertised_host_name] = float_host(node[:fqdn])
node.override[:kafka][:broker][:jmx_port] = node[:bcpc][:hadoop][:kafka][:jmx][:port]
