#
# Cookbook Name:: kafka-bcpc
# Recipe: zookeeper_server

node.default[:bcpc][:hadoop][:kerberos][:enable] = false
include_recipe "bcpc-hadoop::zookeeper_server"
