#
# Cookbook Name:: kafka-bcpc
# Recipe: setattr

# Override JAVA related node attributee
node.override['java']['jdk_version'] = '8'
node.override['java']['jdk']['8']['x86_64']['url'] = get_binary_server_url + "jdk-8u74-linux-x64.tar.gz"

# Get Kafka ZooKeeper servers
# Override ZooKeeper related node attribute if Kafka specific ZooKeeper quorum is used
if node[:use_hadoop_zookeeper_quorum]
  zk_hosts = get_node_attributes(HOSTNAME_NODENO_ATTR_SRCH_KEYS,"zookeeper_server","bcpc-hadoop")
else
  zk_hosts = get_req_node_attributes(get_zk_nodes,HOSTNAME_NODENO_ATTR_SRCH_KEYS)
  node.override[:bcpc][:hadoop][:zookeeper][:servers] = zk_hosts
end
# Override Kafka related node attributes
node.override[:kafka][:broker][:zookeeper][:connect] = zk_hosts.map{|x| float_host(x['hostname'])}
