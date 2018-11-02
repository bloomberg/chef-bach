#
# Cookbook Name:: bcpc_kafka
# Recipe:: default
#
# Kafka-bcpc is essentially a role cookbook. It sets a few attributes
# and includes other recipes.
#
# The 'default' recipe includes the common material shared between
# Zookeeper and Kafka servers in a standalone Kafka cluster.
#

include_recipe 'bcpc::chef_vault_install'
include_recipe 'bcpc::default'
include_recipe 'bcpc::networking'
include_recipe 'bcpc-hadoop::disks'
include_recipe 'bcpc::ubuntu_tools_repo'
include_recipe 'bcpc-hadoop::default'

#
# All of the important Java cookbook attributes are overridden in
# bcpc-hadoop, so we need not set them again.
#
include_recipe 'java'
include_recipe 'java::oracle_jce'
