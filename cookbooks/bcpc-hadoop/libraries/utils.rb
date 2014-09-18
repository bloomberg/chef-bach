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

def init_config
  if not Chef::DataBag.list.key?('configs')
     puts "************ Creating data_bag \"configs\""
     bag = Chef::DataBag.new
     bag.name("configs")
     bag.create
  end rescue nil
  begin
     $dbi = Chef::DataBagItem.load('configs', node.chef_environment)
     $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
     puts "============ Loaded existing data_bag_item \"configs/#{node.chef_environment}\""
  rescue
     $dbi = Chef::DataBagItem.new
     $dbi.data_bag('configs')
     $dbi.raw_data = { 'id' => node.chef_environment }
     $dbi.save
     $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
     puts "++++++++++++ Created new data_bag_item \"configs/#{node.chef_environment}\""
  end
end

def make_config(key, value)
  init_config if $dbi.nil?
  if $dbi[key].nil?
    $dbi[key] = (node['bcpc']['encrypt_data_bag'] ? Chef::EncryptedDataBagItem.encrypt_value(value, Chef::EncryptedDataBagItem.load_secret) : value)
    $dbi.save
    $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
    puts "++++++++++++ Creating new item with key \"#{key}\""
    return value
  else
    puts "============ Loaded existing item with key \"#{key}\""
    return (node['bcpc']['encrypt_data_bag'] ? $edbi[key] : $dbi[key])
  end
end

def get_config(key)
        init_config if $dbi.nil?
        puts "------------ Fetching value for key \"#{key}\""
        return (node['bcpc']['encrypt_data_bag'] ? $edbi[key] : $dbi[key])
end

def get_all_nodes
  results = search(:node, "role:BCPC* AND chef_environment:#{node.chef_environment}")
  if results.any?{|x| x['hostname'] == node['hostname']}
    results.map!{|x| x['hostname'] == node['hostname'] ? node : x}
  else
    results.push(node)
  end
  return results.sort
end

def get_head_nodes
  results = search(:node, "role:BCPC-Headnode AND chef_environment:#{node.chef_environment}")
  results.map!{ |x| x['hostname'] == node[:hostname] ? node : x }
  return (results == []) ? [node] : results.sort
end

def get_hadoop_heads
  results = search(:node, "role:BCPC-Hadoop-Head AND chef_environment:#{node.chef_environment}")
  if results.any?{|x| x['hostname'] == node[:hostname]}
    results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
  else
    results.push(node) if node[:roles].include? "BCPC-Hadoop-Head"
  end
  return results.sort
end

def get_quorum_hosts
  results = search(:node, "(roles:BCPC-Hadoop-Quorumnode or role:BCPC-Hadoop-Head) AND chef_environment:#{node.chef_environment}")
  if results.any?{|x| x['hostname'] == node[:hostname]}
    results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
  else
    results.push(node) if node[:roles].include? "BCPC-Hadoop-Quorumnode"
  end
  return results.sort
end

def get_hadoop_workers
  results = search(:node, "role:BCPC-Hadoop-Worker AND chef_environment:#{node.chef_environment}")
  if results.any?{|x| x['hostname'] == node[:hostname]}
    results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
  else
    results.push(node) if node[:roles].include? "BCPC-Hadoop-Worker"
  end
  return results.sort
end

def get_namenodes()
  # Logic to get all namenodes if running in HA
  # or to get only the master namenode if not running in HA
  if node['bcpc']['hadoop']['hdfs']['HA'] then
    nn_hosts = get_nodes_for("namenode*")
  else
    nn_hosts = get_nodes_for("namenode_no_HA")
  end
  return nn_hosts.sort
end

def get_nodes_for(recipe, cookbook=cookbook_name)
  results = search(:node, "recipes:#{cookbook}\\:\\:#{recipe} AND chef_environment:#{node.chef_environment}")
  results.map!{ |x| x['hostname'] == node[:hostname] ? node : x }
  if node.run_list.expand(node.chef_environment).recipes.include?("#{cookbook}::#{recipe}") and not results.include?(node)
    results.push(node)
  end
  return results.sort
end

def get_binary_server_url
  return("http://#{URI(Chef::Config['chef_server_url']).host}/") if node[:bcpc][:binary_server_url].nil?
  return(node[:bcpc][:binary_server_url])
end

def secure_password(len=20)
  pw = String.new
  while pw.length < len
    pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
  end
  pw
end

def float_host(*args)
  if node[:bcpc][:management][:ip] != node[:bcpc][:floating][:ip]
    return ("f-" + args.join('.'))
  else
    return args.join('.')
  end
end

def storage_host(*args)
  if node[:bcpc][:management][:ip] != node[:bcpc][:floating][:ip]
    return ("s-" + args.join('.'))
  else
    return args.join('.')
  end
end

def znode_exists?(znode_path, zk_host="localhost:2181")
  require 'rubygems'
  require 'zookeeper'
  znode_found = false
  begin
    @zk = Zookeeper.new(zk_host)
    if !@zk.connected?
      raise "znode_exists : Unable to connect to zookeeper"
    end 
    r = @zk.get(:path => znode_path)
    if r[:rc] == 0
      znode_found = true
    end 
  rescue Exception => e
    puts e.message
  ensure
    @zk.close unless @zk.closed?
  end
  return znode_found
end

#
# Library function to get attributes from all namenode node object
#
def get_namenode_attr
  all_node_attr = get_namenodes()
  ret = get_req_node_attributes(all_node_attr,HOSTNAME_NODENO_ATTR_SRCH_KEYS)
  return ret
end

#
# Function to retrieve commonly used node attributes so that the call to chef server is minimized
#
def set_hosts
  node.default[:bcpc][:hadoop][:nn_hosts] = get_namenode_attr()
  node.default[:bcpc][:hadoop][:zookeeper][:servers] = get_node_attributes(HOSTNAME_NODENO_ATTR_SRCH_KEYS,"zookeeper_server","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:jn_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"journalnode","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:rm_hosts] = get_node_attributes(HOSTNAME_NODENO_ATTR_SRCH_KEYS,"resource_manager","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:hs_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"historyserver","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:dn_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"datanode","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:hb_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"hbase_master","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:hive_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"hive_metastore","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:oozie_hosts]  = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"oozie","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:httpfs_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"httpfs","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:rs_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"region_server","bcpc-hadoop")
  node.default[:bcpc][:hadoop][:mysql_hosts] = get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"mysql","bcpc")
end

def zk_formatted?
  require 'rubygems'
  require 'zookeeper'
  z = Zookeeper.new("localhost:2181")
  r = z.get_children(:path => "/hadoop-ha/#{node.chef_environment}")
  return (r[:rc] == 0)
end

#
# Library function to get attributes for nodes that executes a particular recipe
#
def get_node_attributes(srch_keys,recipe,cookbook=cookbook_name)
  node_objects = get_nodes_for(recipe,cookbook)
  ret = get_req_node_attributes(node_objects,srch_keys)
  return ret
end

#
# Library function to retrieve required attributes from a array of node objects passed
# Takes in an array of node objects and a search hash. Refer to comments for the constant
# DEFAULT_NODE_ATTR_SRCH_KEYS regarding the format of the hash
# returns a array of hash with the requested attributes
# [ { :node_number => "val", :hostname => "nameval" }, ...]
#
def get_req_node_attributes(node_objects,srch_keys)
  result = Array.new
  node_objects.each do |obj|
    temp = Hash.new
    srch_keys.each do |name, key|
      val = key.split('.').reduce(obj) {|memo, key| memo[key]}
      temp[name] = val
    end
    result.push(temp)
  end
  return result
end
