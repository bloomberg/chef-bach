#
# Cookbook Name:: kafka-bcpc 
# Recipe: zookeeper_server

include_recipe "bcpc-hadoop::zookeeper_impl"
include_recipe "kafka-bcpc::kafka_queries"
