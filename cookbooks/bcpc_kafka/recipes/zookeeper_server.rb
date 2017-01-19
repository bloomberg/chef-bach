#
# Cookbook Name:: bcpc_kafka
# Recipe: zookeeper_server
#

include_recipe 'bcpc_kafka::default'

node.default[:bcpc][:hadoop][:kerberos][:enable] = false
include_recipe 'bcpc-hadoop::zookeeper_server'

include_recipe 'bcpc::diamond'
include_recipe 'bcpc_jmxtrans'
