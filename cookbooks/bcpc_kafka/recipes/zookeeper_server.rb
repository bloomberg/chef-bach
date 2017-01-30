#
# Cookbook Name:: bcpc_kafka
# Recipe: zookeeper_server
#
# This recipe is essentially a role for Zookeeper servers in a
# standalone Kafka cluster.
#
# In addition to Zookeeper itself, the ZK hosts will be running all
# the cluster maintenance items: mysql, graphite, zabbix etc.
#

include_recipe 'bcpc_kafka::default'

# For the time being, this will have to be force_override.
node.force_override[:bcpc][:hadoop][:kerberos][:enable] = false

include_recipe 'bcpc-hadoop::zookeeper_server'

#
# Zookeeper is hosted on the root disk, so we'll use our
# data volumes for Graphite and MySQL.
#
graphite_directory = '/disk/0/graphite'

directory graphite_directory do
  action :create
  owner 'root'
  group 'root'
end

link node[:bcpc][:graphite][:install_dir] do
  to graphite_directory
end

#
# Ideally mysql and graphite will land on different disks, but we'll
# use a single disk in a pinch.
#
ruby_block 'choose-mysql-directory' do
  block do
    node.run_state[:bcpc_mysql_directory] = if File.exist?('/disk/1')
                                              '/disk/1/mysql'
                                            elsif File.exist?('/disk/0')
                                              '/disk/0/mysql'
                                            else
                                              raise 'No data volumes found!'
                                            end
  end
end

user 'mysql' do
  home lazy { node.run_state[:bcpc_mysql_directory] }
  action :create
  # Don't attempt to edit an existing mysql user.
  not_if 'id mysql'
end

directory 'mysql_directory' do
  path lazy { node.run_state[:bcpc_mysql_directory] }
  action :create
  mode 0700
  owner 'mysql'
  group 'mysql'
end

link '/var/lib/mysql' do
  to lazy { node.run_state[:bcpc_mysql_directory] }
end

include_recipe 'bcpc::mysql'
include_recipe 'bcpc::keepalived'
include_recipe 'bcpc::haproxy'
include_recipe 'bcpc::zabbix-head'
include_recipe 'bcpc::graphite'
include_recipe 'bcpc::diamond'
include_recipe 'bcpc_jmxtrans'
