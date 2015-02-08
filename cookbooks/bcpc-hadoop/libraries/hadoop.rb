#
# Cookbook Name:: bcpc
# Library:: utils
#
# Copyright 2013, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'
require 'thread'

module BcpcHadoop
  module HadoopHelper

#
# Constant string which defines the default attributes which need to be retrieved from node objects
# The format is hash { key => value , key => value }
# Key will be used as the key in the search result which is a hash and the value is the node attribute which needs
# to be included in the result. Attribute hierarchy can be expressed as a dot seperated string. User the following
# as an example
#
    HOSTNAME_ATTR_SRCH_KEYS = {'hostname' => 'hostname'}
    HOSTNAME_NODENO_ATTR_SRCH_KEYS = {'hostname' => 'hostname', 'node_number' => 'bcpc.node_number'}
    MGMT_IP_ATTR_SRCH_KEYS = {'mgmt_ip' => 'bcpc.management.ip'}
    
    def get_hadoop_heads(node=node)
      results = search(:node, "role:BCPC-Hadoop-Head AND chef_environment:#{node.chef_environment}")
      if results.any?{|x| x['hostname'] == node[:hostname]}
        results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
      else
        results.push(node) if node[:roles].include? "BCPC-Hadoop-Head"
      end
      return results.sort
    end
    module_function :get_hadoop_heads

    def get_quorum_hosts(node=node)
      results = search(:node, "(roles:BCPC-Hadoop-Quorumnode or role:BCPC-Hadoop-Head) AND chef_environment:#{node.chef_environment}")
      if results.any?{|x| x['hostname'] == node[:hostname]}
        results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
      else
        results.push(node) if node[:roles].include? "BCPC-Hadoop-Quorumnode"
      end
      return results.sort
    end
    module_function :get_quorum_hosts
    
    def get_hadoop_workers(node=node)
      results = search(:node, "role:BCPC-Hadoop-Worker AND chef_environment:#{node.chef_environment}")
      if results.any?{|x| x['hostname'] == node[:hostname]}
        results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
      else
        results.push(node) if node[:roles].include? "BCPC-Hadoop-Worker"
      end
      return results.sort
    end
    module_function :get_hadoop_workers
    
    def get_namenodes(node=node,cookbook=cookbook_name)
      # Logic to get all namenodes if running in HA
      # or to get only the master namenode if not running in HA
      if node['bcpc']['hadoop']['hdfs']['HA'] then
        nn_hosts = Bcpc::OSHelper.get_nodes_for("namenode*",node,cookbook)
      else
        nn_hosts = Bcpc::OSHelper.get_nodes_for("namenode_no_HA",node,cookbook)
      end
      return nn_hosts.sort
    end
    module_function :get_namenodes

    def znode_exists?(znode_path, zk_host="localhost:2181")
      require 'rubygems'
      require 'zookeeper'
      znode_found = false
      begin
        zk = Zookeeper.new(zk_host)
        if !zk.connected?
          raise "znode_exists : Unable to connect to zookeeper quorum #{zk_host}"
        end 
        r = zk.get(:path => znode_path)
        if r[:rc] == 0
          znode_found = true
        end 
      rescue Exception => e
        puts e.message
      ensure
        if !zk.nil?
          zk.close unless zk.closed?
        end
      end
      return znode_found
    end
    module_function :znode_exists?
    
    #
    # Library function to get attributes from all namenode node object
    #
    def get_namenode_attr(node=node,cookbook=cookbook_name)
      all_node_attr = get_namenodes(node,cookbook)
      ret = Bcpc::OSHelper.get_req_node_attributes(all_node_attr,HOSTNAME_NODENO_ATTR_SRCH_KEYS)
      return ret
    end
    module_function :get_namenode_attr

    #
    # Function to retrieve commonly used node attributes so that the call to chef server is minimized
    #
    def set_hosts(node=node,cookbook=cookbook_name)
      node.default[:bcpc][:hadoop][:nn_hosts] = get_namenode_attr(node,cookbook)
      node.default[:bcpc][:hadoop][:zookeeper][:servers] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_NODENO_ATTR_SRCH_KEYS,"zookeeper_server",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:jn_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"journalnode",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:rm_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_NODENO_ATTR_SRCH_KEYS,"resource_manager",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:hs_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"historyserver",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:dn_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"datanode",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:hb_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"hbase_master",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:hive_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"hive_metastore",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:oozie_hosts]  =Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"oozie",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:httpfs_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"httpfs",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:rs_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"region_server",node,"bcpc-hadoop")
      node.default[:bcpc][:hadoop][:mysql_hosts] = Bcpc::OSHelper.get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"mysql",node,"bcpc")
    end
    module_function :set_hosts
    
    def zk_formatted?(node=node)
      require 'rubygems'
      require 'zookeeper'
      z = Zookeeper.new("localhost:2181")
      r = z.get_children(:path => "/hadoop-ha/#{node.chef_environment}")
      return (r[:rc] == 0)
    end
    module_function :zk_formatted?
    
    #
    # Restarting of hadoop processes need to be controlled in a way that all the nodes
    # are not down at the sametime, the consequence of which will impact users. In order
    # to achieve this, nodes need to acquire a lock before restarting the process of interest.
    # This function is to acquire the lock which is a znode in zookeeper. The znode name is the name  
    # of the service to be restarted for e.g "hadoop-hdfs-datanode" and is located by default at "/".
    # The imput parameters are service name along with the ZK path (znode name), string of zookeeper 
    # servers ("zk_host1:port,sk_host2:port"), and the fqdn of the node acquiring the lock
    #
    def acquire_restart_lock(znode_path, zk_hosts="localhost:2181",node_name)
      require 'zookeeper'
      lock_acquired = false
      zk = nil
      begin
        zk = Zookeeper.new(zk_hosts)
        if !zk.connected?
          raise "acquire_restart_lock : unable to connect to ZooKeeper"
        end
        ret = zk.create(:path => znode_path, :data => node_name)
        if ret[:rc] == 0
          lock_acquired = true
        end
      rescue Exception => e
        puts e.message
      ensure
        if !zk.nil?
          zk.close unless zk.closed? 
        end
      end
      return lock_acquired
    end
    module_function :acquire_restart_lock
    
    #
    # This function is to check whether the lock to restart a particular service is held by a node.
    # The input parameters are the path to the znode used to restart a hadoop service, a string containing the 
    # host port values of the ZooKeeper nodes "host1:port, host2:port" and the fqdn of the host
    #
    def my_restart_lock?(znode_path,zk_hosts="localhost:2181",node_name)
      require 'zookeeper'
      my_lock = false
      zk = nil
      begin
        zk = Zookeeper.new(zk_hosts)
        if !zk.connected?
          raise "my_restart_lock?: unable to connect to ZooKeeper"
        end
        ret = zk.get(:path => znode_path)
        val = ret[:data]
        if val == node_name
          my_lock = true
        end
      rescue Exception => e
        puts e.message
      ensure
        if !zk.nil?
          zk.close unless zk.closed?
        end
      end
      return my_lock
    end
    module_function :my_restart_lock?
    
    #
    # Function to release the lock held by the node to restart a particular hadoop service
    # The input parameters are the name of the path to znode which was used to lock for restarting service,
    # string containing the zookeeper host and port ("host1:port,host2:port") and the fqdn
    # of the node trying to release the lock.
    #
    def rel_restart_lock(znode_path, zk_hosts="localhost:2181",node_name)
      require 'zookeeper'
      lock_released = false
      zk = nil
      begin
        zk = Zookeeper.new(zk_hosts)
        if !zk.connected?
          raise "rel_restart_lock : unable to connect to ZooKeeper"
        end
        if my_restart_lock?(znode_path, zk_hosts, node_name)
          ret = zk.delete(:path => znode_path)
        else
          raise "rel_restart_lock : node who is not the owner is trying to release the lock"
        end
        if ret[:rc] == 0
          lock_released = true
        end
      rescue Exception => e
        puts e.message
      ensure
        if !zk.nil?
          zk.close unless zk.closed? 
        end
      end
      return lock_released
    end
    module_function :rel_restart_lock
    
    #
    # Function to get the node name which is holding a particular service restart lock
    # Input parameters: The path to the znode (lock) and the string of zookeeper hosts:port 
    #
    def get_restart_lock_holder(znode_path, zk_hosts="localhost:2181")
      require 'zookeeper'
      begin
        zk = Zookeeper.new(zk_hosts)
        if !zk.connected?
          raise "get_restart_lock_holder : unable to connect to ZooKeeper"
        end
        ret = zk.get(:path => znode_path)
        if ret[:rc] == 0
          val = ret[:data]
        end
      rescue Exception => e
        puts e.message
      ensure
        if !zk.nil?
          zk.close unless zk.closed?
        end
      end
      return val
    end
    module_function :get_restart_lock_holder

  end
end

Chef::Recipe.send(:include, BcpcHadoop::HadoopHelper)
