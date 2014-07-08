#
# Cookbook Name:: kafka-bcpc
# Recipe: setattr

# Override JAVA related node attributee
node.override['java']['jdk_version'] = '7'
node.override['java']['jdk']['7']['x86_64']['url'] = get_binary_server_url + "jdk-7u51-linux-x64.tar.gz"
node.override['java']['jdk']['7']['i586']['url'] = get_binary_server_url + "jdk-7u51-linux-i586.tar.gz"
# Override Kafka related node attributes
zk_hosts = get_zk_nodes.map!{|x| x.bcpc.management.ip}
node.override[:kafka][:zookeeper][:connect] = zk_hosts
node.override[:zookeeper][:servers] = zk_hosts
node.override[:kafka][:base_url] = get_binary_server_url + "kafka"
node.override[:kafka][:host_name] = float_host(node[:fqdn])
node.override[:kafka][:advertised_host_name] = float_host(node[:fqdn])
node.override[:kafka][:advertised_port] = 9092

