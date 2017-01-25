#
# Cookbook Name:: bcpc_kafka
# Recipe: zookeeper_server
#

include_recipe 'bcpc_kafka::default'

# For the time being, this will have to be force_override.
node.force_override[:bcpc][:hadoop][:kerberos][:enable] = false

include_recipe 'bcpc-hadoop::zookeeper_server'

include_recipe 'bcpc::diamond'
include_recipe 'bcpc_jmxtrans'
