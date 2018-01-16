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
require 'cluster_def'

#
# Constant string which defines the default attributes which
# need to be retrieved from node objects
# The format is hash { key => value , key => value }
# Key will be used as the key in the search result which is a hash 
# and the value is the node attribute which needs
# to be included in the result. Attribute hierarchy can be expressed as a 
# dot seperated string. User the following
# as an example
#

# For Kerberos to work we need FQDN for each host. Changing "HOSTNAME" to "FQDN".
# Hadoop breaks principal into 3 parts  (Service, FQDN and REALM)

HOSTNAME_ATTR_SRCH_KEYS = {'hostname' => 'fqdn'}.freeze
HOSTNAME_NODENO_ATTR_SRCH_KEYS = {'hostname' => 'fqdn',
                                  'node_number' => 'bcpc.node_number',
                                  'zookeeper_myid' => 'bcpc.hadoop.zookeeper.myid'}.freeze
MGMT_IP_ATTR_SRCH_KEYS = {'mgmt_ip' => 'bcpc.management.ip'}.freeze

def init_config
  begin
     $dbi = Chef::DataBagItem.load('configs', node.chef_environment)
     $edbi = Chef::EncryptedDataBagItem.load(
       'configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
     puts "============ Loaded existing data_bag_item \"configs/#{node.chef_environment}\""
  rescue
     $dbi = Chef::DataBagItem.new
     $dbi.data_bag('configs')
     $dbi.raw_data = { 'id' => node.chef_environment }
     $dbi.save
     $edbi = Chef::EncryptedDataBagItem.load(
       'configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
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

def make_config!(key, value)
  init_config if $dbi.nil?
  $dbi[key] = (node['bcpc']['encrypt_data_bag'] ? Chef::EncryptedDataBagItem.encrypt_value(value, Chef::EncryptedDataBagItem.load_secret) : value)
  $dbi.save
  $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
  puts "++++++++++++ Updating existing item with key \"#{key}\""
  value
end

def get_hadoop_heads
  results = fetch_all_nodes.select { |hst| hst[:runlist].include? "role[BCPC-Hadoop-Head]" }
  if results.any?{|x| x['hostname'] == node[:hostname]}
    results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
  else
    results.push(node) if node[:roles].include? "BCPC-Hadoop-Head"
  end
  return results.sort_by{ |h| h[:node_id]}
end

def get_timeline_servers
  results = Chef::Search::Query.new.search(:node, "roles:BCPC-Hadoop-Head-YarnTimeLineServer AND chef_environment:#{node.chef_environment}").first
  if results.any? { |x| x['hostname'] == node['hostname'] }
    results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  elsif node['roles'].include? 'BCPC-Hadoop-Head-YarnTimeLineServer'
    results.push(node)
  end
  results.sort
end


def get_quorum_hosts
  results = fetch_all_nodes.select { |hst| hst[:runlist].include? "role[BCPC-Hadoop-Quorumnode]" or hst[:runlist].include? "role[BCPC-Hadoop-Head]" }
  if results.any?{|x| x['hostname'] == node[:hostname]}
    results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
  else
    results.push(node) if node[:roles].include? "BCPC-Hadoop-Quorumnode"
  end
  return results.sort_by{ |h| h[:node_id]}
end

def get_hadoop_workers
  results = fetch_all_nodes.select { |hst| hst[:runlist].include? "role[BCPC-Hadoop-Worker]" }
  if results.any?{|x| x['hostname'] == node[:hostname]}
    results.map!{|x| x['hostname'] == node[:hostname] ? node : x}
  else
    results.push(node) if node[:roles].include? "BCPC-Hadoop-Worker"
  end
  return results.sort_by{ |h| h[:fqdn]}
end

def get_namenodes
  # Logic to get all namenodes if running in HA
  # or to get only the master namenode if not running in HA
  if node['bcpc']['hadoop']['hdfs']['HA']
    nn_hosts = fetch_all_nodes.select { |hst| hst[:runlist].include? "role[BCPC-Hadoop-Head-Namenode]" or hst[:runlist].include? "role[BCPC-Hadoop-Head-Namenode-Standby]" }
  else
    nn_hosts = fetch_all_nodes.select { |hst| hst[:runlist].include? "role[BCPC-Hadoop-Head-Namenode-NoHA]" }
  end
  return nn_hosts.uniq{ |x| float_host(x[:hostname]) }.sort_by{ |h| h[:node_id]}
end

def get_nodes_for(recipe, cookbook = cookbook_name)
  results = Chef::Search::Query.new.search(:node, "recipes:#{cookbook}\\:\\:#{recipe} AND chef_environment:#{node.chef_environment}").first
  results.map! { |x| x['hostname'] == node['hostname'] ? node : x }
  recipes = node.run_list.expand(node.chef_environment).recipes
  if recipes.include?("#{cookbook}::#{recipe}") && !results.include?(node)
    results.push(node)
  end
  results.sort
end

def get_binary_server_url
  return("http://#{URI(Chef::Config['chef_server_url']).host}/") if node['bcpc']['binary_server_url'].nil?
  node['bcpc']['binary_server_url']
end

def secure_password(len = 20)
  pw = ''
  pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '') while pw.length < len
  pw
end

def float_host(*args)
  return ('f-' + args.join('.')) if node['bcpc']['management']['ip'] != node['bcpc']['floating']['ip']
  args.join('.')
end

def storage_host(*args)
  return ('s-' + args.join('.')) if node['bcpc']['management']['ip'] != node['bcpc']['floating']['ip']
  args.join('.')
end

def znode_exists?(znode_path, zk_host = 'localhost:2181')
  require 'rubygems'
  require 'zookeeper'
  rc = Zookeeper::Constants::ZSYSTEMERROR
  begin
    zk = Zookeeper.new(zk_host)
    raise "znode_exists : Unable to connect to zookeeper quorum #{zk_host}" unless zk.connected?
    r = zk.get(path: znode_path)
    rc = r[:rc]
  ensure
    zk.close if !zk.nil? && !zk.closed?
  end

  return true if rc == Zookeeper::Constants::ZOK
  return false if rc == Zookeeper::Constants::ZNONODE

  raise "get znode #{znode_path} failed with rc = #{rc}, zk_host=#{zk_host}"
end

  
#
# Function to retrieve commonly used node attributes.
# Minimizes calls to the chef server.
#
def set_hosts
  if node.run_state['cluster_def'].nil? then
    node.run_state['cluster_def'] = BACH::ClusterDef.new(node_obj: node)
  end
  hosts = node.run_state['cluster_def'].fetch_cluster_def

  # host search helper lambdas
  runs_role = Proc.new { |host, role| role && host[:runlist].include?(role) }
  runs_recipe = Proc.new { |host, recipe| recipe && host[:runlist].include?(recipe) }

  # mapped host objects
  to_host = Proc.new do |host| {
    'hostname' => host[:fqdn],
    'node_number' => host[:node_id],
    'zookeeper_myid' => nil
  } end

  node['bcpc']['hadoop']['services'].each do |name, service|
    *keys, last = ['bcpc', 'hadoop', *service['key']]
    keys.inject(node.default, :fetch)[last] =
      hosts.select do |h|
        runs_role.call(h, service['role']) ||
        runs_recipe.call(h, service['recipe'])
      end.map do |h|
        to_host.call(h)
      end
  end

  # set the oozie_url
  oozie_hosts = node['bcpc']['hadoop']['oozie_hosts']
  vip_host = float_host(node['bcpc']['management']['viphost'])
  first_host = float_host(oozie_hosts.first['hostname'])
  oozie_ha_port = node['bcpc']['ha_oozie']['port']
  oozie_port = node['bcpc']['hadoop']['oozie_port']

  node.default['bcpc']['hadoop']['oozie_url'] =
    if oozie_hosts.length > 1
      # high-availability
      "http://#{vip_host}:#{oozie_ha_port}/oozie"
    elsif oozie_hosts.length == 1
      # single oozie host
      "http://#{first_host}/#{oozie_port}/oozie"
    end

  # set the resourcemanager_url (rm_address)
  rm_hosts = node['bcpc']['hadoop']['rm_hosts']
  first_host = float_host(rm_hosts.first['hostname'])
  rm_port = node['bcpc']['hadoop']['yarn']['resourcemanager']['port']

  node.default['bcpc']['hadoop']['rm_address'] =
    if rm_hosts.length > 1
      # high-availability
      node.chef_environment
    elsif rm_hosts.length == 1
      # single resourcemanager host
      "#{first_host}:#{rm_port}"
    end
end

#
# Restarting of hadoop processes need to be controlled in a way that all the nodes
# are not down at the sametime, the consequence of which will impact users. In order
# to achieve this, nodes need to acquire a lock before restarting the process of interest.
# This function is to acquire the lock which is a znode in zookeeper. The znode name is the name
# of the service to be restarted for e.g "hadoop-hdfs-datanode" and is located by default at "/".
# The imput parameters are service name along with the ZK path (znode name), string of zookeeper
# servers ("zk_host1:port,sk_host2:port"), and the fqdn of the node acquiring the lock
# Return value : true or false
#
def acquire_restart_lock(znode_path, node_name, zk_hosts = 'localhost:2181')
  require 'zookeeper'
  lock_acquired = false
  zk = nil
  begin
    zk = Zookeeper.new(zk_hosts)
    raise "acquire_restart_lock : unable to connect to ZooKeeper quorum #{zk_hosts}" unless zk.connected?
    ret = zk.create('path' => znode_path, 'data' => node_name)
    lock_acquired = true if ret[:rc] == Zookeeper::Constants::ZOK
  rescue => e
    puts e.message
  ensure
    zk.close if !zk.nil? && !zk.closed?
  end
  lock_acquired
end

#
# This function is to check whether the lock to restart a particular service is held by a node.
# The input parameters are the path to the znode used to restart a hadoop service, a string containing the
# host port values of the ZooKeeper nodes "host1:port, host2:port" and the fqdn of the host
# Return value : true or false
#
def my_restart_lock?(znode_path, node_name, zk_hosts = 'localhost:2181')
  require 'zookeeper'
  my_lock = false
  zk = nil
  begin
    zk = Zookeeper.new(zk_hosts)
    raise "my_restart_lock?: unable to connect to ZooKeeper quorum #{zk_hosts}" unless zk.connected?
    ret = zk.get(path: znode_path)
    val = ret['data']
    my_lock = true if val == node_name
  rescue => e
    puts e.message
  ensure
    zk.close if !zk.nil? && !zk.closed?
  end
  my_lock
end

#
# Function to release the lock held by the node to restart a particular hadoop service
# The input parameters are the name of the path to znode which was used to lock for restarting service,
# string containing the zookeeper host and port ("host1:port,host2:port") and the fqdn
# of the node trying to release the lock.
# Return value : true or false based on whether the lock release was successful or not
#
def rel_restart_lock(znode_path, node_name, zk_hosts = 'localhost:2181')
  require 'zookeeper'
  lock_released = false
  zk = nil
  begin
    zk = Zookeeper.new(zk_hosts)
    raise "rel_restart_lock : unable to connect to ZooKeeperi quorum #{zk_hosts}" unless zk.connected?
    raise 'rel_restart_lock : node who is not the owner is trying to release the lock' unless my_restart_lock?(znode_path, node_name, zk_hosts)
    ret = zk.delete('path' => znode_path)
    lock_released = true if ret[:rc] == Zookeeper::Constants::ZOK
  rescue => e
    puts e.message
  ensure
    zk.close if !zk.nil? && !zk.closed?
  end

  lock_released
end

#
# Function to get the node name which is holding a particular service restart lock
# Input parameters: The path to the znode (lock) and the string of zookeeper hosts:port
# Return value    : The fqdn of the node which created the znode to restart or nil
#
def get_restart_lock_holder(znode_path, zk_hosts = 'localhost:2181')
  require 'zookeeper'
  begin
    zk = Zookeeper.new(zk_hosts)
    raise "get_restart_lock_holder : unable to connect to ZooKeeper quorum #{zk_hosts}" unless zk.connected?
    ret = zk.get(path: znode_path)
    val = ret['data'] if ret[:rc] == Zookeeper::Constants::ZOK
  rescue => e
    puts e.message
  ensure
    zk.close if !zk.nil? && !zk.closed?
  end
  val
end

#
# Function to generate the full path of znode which will be used to create a restart lock znode
# Input paramaters: The path in ZK where znodes are created for the retart locks and the lock name
# Return value    : Fully formed path which can be used to create the znode
#
def format_restart_lock_path(root, lock_name)
  return "/#{lock_name}" if root.nil?
  return "/#{lock_name}" if root == '/'
  "#{root}/#{lock_name}"
end

#
# Function to identify start time of a process
# Input paramater: string to identify the process through pgrep command
# Returned value : The starttime for the process. If multiple instances are returned from pgrep
# command, time returned will be the earliest time of all the instances
#
def process_start_time(process_identifier)
  require 'time'
  begin
    target_process_pid = `pgrep -f #{process_identifier}`

    return nil if target_process_pid == ''

    target_process_pid_arr = target_process_pid.split('\n').map { |pid| `ps --no-header -o lstart #{pid}`.strip }
    start_time_arr = []
    target_process_pid_arr.each do |t|
      start_time_arr.push(Time.parse(t)) if t != ''
    end
    return start_time_arr.sort.first.to_s
  end
end

#
# Function to check whether a process was started manually after restart of the process failed during prev chef client run
# Input paramaters : Last restart failure time, string to identify the process
# Returned value   : true or false
#
def process_restarted_after_failure?(restart_failure_time, process_identifier)
  require 'time'
  begin
    start_time = process_start_time(process_identifier)
    if not start_time.nil? && (Time.parse(restart_failure_time).to_i < Time.parse(start_time).to_i)
      Chef::Log.info("#{process_identifier} seem to be started at #{start_time} after last restart failure at #{restart_failure_time}")
      return true
    end

    return false
  end
end

def user_exists?(user_name)
  user_found = false
  chk_usr_cmd = "getent passwd #{user_name}"
  Chef::Log.debug("Executing command: #{chk_usr_cmd}")
  cmd = Mixlib::ShellOut.new(chk_usr_cmd, 'timeout' => 10).run_command
  user_found = true if cmd.exitstatus == 0

  user_found
end

def group_exists?(group_name)
  chk_grp_cmd = "getent group #{group_name}"
  Chef::Log.debug("Executing command: #{chk_grp_cmd}")
  cmd = Mixlib::ShellOut.new(chk_grp_cmd, 'timeout' => 10).run_command
  cmd.exitstatus == 0 ? true : false
end

def get_group_action(group_name)
  group_exists?(group_name) ? :manage : :create
end

def vip?
  cmd = Mixlib::ShellOut.new(
    'ip addr show', 'timeout' => 10
  ).run_command
  cmd.stderr.empty? && cmd.stdout.include?(node['bcpc']['management']['vip'])
end

# Internal: Check if oozie server is running on the given host.
#
# host - Endpoint (FQDN/IP) on which Oozie server is available.
#
# Examples
#
#   oozie_running?("f-bcpc-vm2.bcpc.example.com")
#   # => true
#
# Returns true if oozie server is operational 
# with 'NORMAL' status, false otherwise.
def oozie_running?(host)
  oozie_url = "sudo -u oozie oozie admin -oozie http://#{host}:11000/oozie -status"
  cmd = Mixlib::ShellOut.new(
    oozie_url, 'timeout' => 20
  ).run_command
  Chef::Log.debug("Oozie status: #{cmd.stdout}")
  cmd.exitstatus == 0 && cmd.stdout.include?('NORMAL')
end

# Internal: Have the specified Oozie host update its ShareLib 
#           to the latest lib_<timestamp>
#           sharelib directory on hdfs:/user/oozie/share/lib/,
#           without having to restart
#           that Oozie server. Oozie server, by default, uses 
#           the latest one when it (re)starts.
#
# host - Endpoint (FQDN/IP) on which Oozie server is available.
#
# Returns nothing.
def update_oozie_sharelib(host)
  if oozie_running?(host)
    update_sharelib = "sudo -u oozie oozie admin -oozie http://#{host}:11000/oozie -sharelibupdate"
    cmd = Mixlib::ShellOut.new(
      update_sharelib, 'timeout' => 20
    ).run_command
    if cmd.exitstatus == 0
      Chef::Log.info("Sharelibupdate: Updated sharelib on #{host}")
    else
      Chef::Log.info("Sharelibupdate: sharelibupdate command failed on #{host}")
      Chef::Log.info("  stdout: #{cmd.stdout}")
      Chef::Log.info("  stderr: #{cmd.stderr}")
    end
  else
    Chef::Log.info("Sharelibupdate: Oozie server not running on #{host}")
  end
end
