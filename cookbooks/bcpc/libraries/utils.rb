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
require 'base64'
require 'thread'
require 'ipaddr'

# create databag if missing
def create_databag(name)
  if !Chef::DataBag.list.key?(name)
    bag = Chef::DataBag.new
    bag.name(name)
    bag.create
  end
end

# memrize function to bootstrap info
def get_bootstrap
  node.run_state['bootstrap_host'] ||= get_all_nodes.select{|s| s.hostname.include? 'bootstrap'}[0].fqdn
end

#
# Constant string which defines the default attributes which need to be retrieved from node objects
# The format is hash { key => value , key => value }
# Key will be used as the key in the search result which is a hash and the value is the node attribute which needs
# to be included in the result. Attribute hierarchy can be expressed as a dot seperated string. User the following
# as an example
#
HOSTNAME_MGMT_IP_ATTR_SRCH_KEYS = {'hostname' => 'hostname', 'mgmt_ip' => 'bcpc.management.ip'}
MGMT_IP_GRAPHITE_WEBPORT_ATTR_SRCH_KEYS = {'mgmt_ip' => 'bcpc.management.ip', 'graphite_webport' => 'bcpc.graphite.web_port'}

def init_config
  if not Chef::DataBag.list.key?('configs')
    Chef::Log.info "************ Creating data_bag \"configs\""
    bag = Chef::DataBag.new
    bag.name("configs")
    bag.create
  end rescue nil
  begin
    $dbi = Chef::DataBagItem.load('configs', node.chef_environment)
    $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
    Chef::Log.info "============ Loaded existing data_bag_item \"configs/#{node.chef_environment}\""
  rescue
    $dbi = Chef::DataBagItem.new
    $dbi.data_bag('configs')
    $dbi.raw_data = { 'id' => node.chef_environment }
    $dbi.save
    $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
    Chef::Log.info "++++++++++++ Created new data_bag_item \"configs/#{node.chef_environment}\""
  end
end

def make_config(key, value)
  init_config if $dbi.nil?
  if $dbi[key].nil?
    $dbi[key] = (node['bcpc']['encrypt_data_bag'] ? Chef::EncryptedDataBagItem.encrypt_value(value, Chef::EncryptedDataBagItem.load_secret) : value)
    $dbi.save
    $edbi = Chef::EncryptedDataBagItem.load('configs', node.chef_environment) if node['bcpc']['encrypt_data_bag']
    Chef::Log.info "++++++++++++ Creating new item with key \"#{key}\""
    return value
  else
    Chef::Log.info "============ Loaded existing item with key \"#{key}\""
    return (node['bcpc']['encrypt_data_bag'] ? $edbi[key] : $dbi[key])
  end
end

# get value for data bag/chef-vault item with key
# bag: databag name of chef vault item; 
# item: chef vault item; 
# key: the key to retrieve password in the item
def get_config(key, item=node.chef_environment, bag="configs")

  #
  # This was the original get_config.
  # It fetches things out of chef data bags.
  #
  def get_data_bag_item(key, item, bag)
    if bag == 'configs'
      init_config if $dbi.nil?
      Chef::Log.info  "Fetching non-vaulted value for key \"#{key}\""
      node['bcpc']['encrypt_data_bag'] ? $edbi[key] : $dbi[key]
    else
      begin
        entry = Chef::DataBagItem.load(bag,item)
        return entry[key]
      rescue
        nil
      end
    end
  end

  #
  # This is the second iteration of get_config.
  # Items are retrieved from chef-vault.
  #
  def get_vault_item(key, item, bag)
    begin
      require 'chef-vault'
      ChefVault::Item.load(bag, item)[key]
    rescue LoadError
      Chef::Log.warn('Could not require chef-vault!')
      nil
    rescue ChefVault::Exceptions::KeysNotFound
      nil
    end
  end

  #
  # We should always provide the vault item if possible.
  # If that fails, fall back to the data bag.
  #
  get_vault_item(key, item, bag) || get_data_bag_item(key, item, bag)
end

def delete_config(key)
  if !$dbi.nil? && $dbi.has_key?(key)
    Chef::Log.info "++++++++++++ Found key #{key}. Deleting it now.... +++++++++++++++++++++++"
    $dbi.delete(key) 
    $dbi.save
  else
    Chef::Log.info "++++++++++++ Couldn't find key #{key} for deletion +++++++++++++++++++++++"
  end
end

def get_config!(key,item=node.chef_environment,bag="configs")
  value = get_config(key,item,bag)
  raise "Failed to find value for #{key}!" if value.nil?
  return value
end

# Get all nodes for this Chef environment
def get_all_nodes
  results = search(:node, "chef_environment:#{node.chef_environment}")
  if results.any?{|x| x['hostname'] == node['hostname']}
    results.map!{|x| x['hostname'] == node['hostname'] ? node : x}
  else
    results.push(node)
  end
  return results.sort
end

def get_cached_head_node_names
  headnodes = []
  begin 
    File.open("/etc/headnodes", "r") do |infile|    
      while (line = infile.gets)
        line.strip!
        if line.length>0 and not line.start_with?("#")
          headnodes << line.strip
        end
      end    
    end
  rescue Errno::ENOENT
    # assume first run   
  end
  return headnodes.sort
end

def get_head_nodes
  results = search(:node, "role:BCPC-Headnode AND chef_environment:#{node.chef_environment}")
  # this returns the node object for the current host before it has been set in Postgress
  results.map!{ |x| x.hostname == node.hostname ? node : x }
  return (results.empty?) ? [node] : results.sort
end

def get_nodes_for(recipe, cookbook=cookbook_name)
  results = search(:node, "recipes:#{cookbook}\\:\\:#{recipe} AND chef_environment:#{node.chef_environment}")
  results.map!{ |x| x['hostname'] == node[:hostname] ? node : x }
  if node.run_list.expand(node.chef_environment).recipes.include?("#{cookbook}::#{recipe}") and not results.include?(node)
    results.push(node)
  end
  return results.sort
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
      begin
        val = key.split('.').reduce(obj) {|memo, sub_key| memo[sub_key]}
      rescue
        Chef::Log.fatal "Node #{obj} does not have key #{key}!"
      end
      temp[name] = val
    end
    result.push(temp)
  end
  return result
end

def get_binary_server_url
  return("http://#{URI(Chef::Config['chef_server_url']).host}/") if node[:bcpc][:binary_server_url].nil?
  return(node[:bcpc][:binary_server_url])
end

def power_of_2(number)
  result = 1
  while (result < number) do result <<= 1 end
  return result
end

def secure_password(len=20)
  pw = String.new
  while pw.length < len
    pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
  end
  pw
end

def secure_password_alphanum_upper(len=20)
    # Chef's syntax checker doesn't like multiple exploders in same line. Sigh.
    alphanum_upper = [*'0'..'9']
    alphanum_upper += [*'A'..'Z']
    # We could probably optimize this to be in one pass if we could easily
    # handle the case where random_bytes doesn't return a rejected char.
    raw_pw = String.new
    while raw_pw.length < len
        raw_pw << ::OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
    end
    pw = String.new
    while pw.length < len
        pw << alphanum_upper[raw_pw.bytes().to_a()[pw.length] % alphanum_upper.length]
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

# requires cidr in form '1.2.3.0/24', where 1.2.3.0 is a dotted quad ip4 address 
# and 24 is a number of netmask bits (e.g. 8, 16, 24)
def calc_reverse_dns_zone(cidr)

  # Validate and parse cidr as an IP
  cidr_ip = IPAddr.new(cidr) # Will throw exception if cidr is bad.

  # Pull out the netmask and throw an error if we can't find it.
  netmask = cidr.split('/')[1].to_i
  raise ("Couldn't find netmask portion of CIDR in #{cidr}.") unless netmask > 0  # nil.to_i == 0, "".to_i == 0  Should always be one of [8,16,24]

  # Knock off leading quads in the reversed IP as specified by the netmask.  (24 ==> Remove one quad, 16 ==> remove two quads, etc)
  # So for example: 192.168.100.0, we'd expect the following input/output:
  # Netmask:   8  => 192.in-addr.arpa         (3 quads removed)
  #           16  => 168.192.in-addr.arpa     (2 quads removed)
  #           24  => 100.168.192.in-addr.arpa (1 quad removed)
  
  reverse_ip = cidr_ip.reverse   # adds .in-addr.arpa automatically
  (4 - (netmask.to_i/8)).times{ reverse_ip = reverse_ip.split('.')[1..-1].join('.')  }  # drop off element 0 each time through

  return reverse_ip

end

# Internal: Check if the given host is the Zabbix leader 
#
# host - host id (eg: hostname) 
#
# Examples
#
#   is_zabbix_leader?("bcpc-vm1")
#   # => true
#
# Returns true if given host is the Zabbix leader, false otherwise 
def is_zabbix_leader?(host)
  leader_check = "mysql -u#{get_config('mysql-zabbix-user')} -p#{get_config!('password','mysql-zabbix','os')} #{node['bcpc']['zabbix_dbname']} --raw --batch -e 'select host_id from leader_election where id=1' "
  cmd = Mixlib::ShellOut.new(
    leader_check, :timeout => 10
  ).run_command
  Chef::Log.debug("is_zabbix_leader: #{cmd.stdout}")
  cmd.exitstatus == 0 && cmd.stdout.include?(host)
end
