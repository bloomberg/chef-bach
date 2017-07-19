#
# Cookbook Name:: bcpc
# Recipe:: default
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

require 'uri'
ubuntu_archive_host = URI.parse(node[:ubuntu][:archive_url]).host
ubuntu_archive_proxy_string = if node[:bcpc][:bootstrap][:proxy]
                                '"' + node[:bcpc][:bootstrap][:proxy] + '"'
                              else
                                'DIRECT'
                              end

file '/etc/apt/apt.conf.d/99ubuntu_archive_proxy' do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    Acquire::http::Proxy {
      #{ubuntu_archive_host} #{ubuntu_archive_proxy_string};
    };
  EOM
end

include_recipe 'bcpc::nscd'
include_recipe 'bcpc::packages'
include_recipe 'ubuntu'
include_recipe 'bcpc::cluster_local_repository'
include_recipe 'bcpc::jmxtrans_agent'

require 'ipaddr'

ifs = node[:network][:interfaces].keys

# create a hash of ipaddresses -- skip interfaces without addresses
ips = ifs.map{ |a| node[:network][:interfaces][a].attribute?(:addresses) and
                     node[:network][:interfaces][a][:addresses] or {}}.reduce({}, :merge)

# build a list of networks on this machine
nets = ips.keys.select{ |ip| ips[ip]['family'] == "inet" }.map{ |ip| IPAddr.new("#{ip}/#{ips[ip]['prefixlen']}") }

# find which subnet contains this machine's management network
subnet = node[:bcpc][:networks].keys.map do |env_net|
  matches = nets.select{|n| n == IPAddr.new(node[:bcpc][:networks][env_net][:management][:cidr])}
  if matches.length >= 1
    env_net
  else
    false
  end
end.select{|n| n}.first

raise "Could not find subnet!" if subnet.nil?
node.default['bcpc']['management']['subnet'] = subnet

mgmt_cidr = IPAddr.new(node['bcpc']['networks'][subnet]['management']['cidr'])
mgmt_vip = IPAddr.new(node['bcpc']['networks'][subnet]['management']['vip'])

# select the first IP address which is on the management network
plausible_ips = ips.select {|ip,v| v['family'] == "inet" and
                            ip != mgmt_vip and mgmt_cidr===ip}.first
if not plausible_ips or plausible_ips.length < 1
  raise "Unable to find any plausible IPs for node['bcpc']['management']['ip']\nPossible IPs: #{ips}\nCan not match #{mgmt_vip} and must be in network #{subnet} -- #{mgmt_cidr.to_range}"
end

node.default['bcpc']['management']['ip'] = ips.select {|ip,v| v['family'] == "inet" and
                                                   ip != mgmt_vip and mgmt_cidr===ip}.first[0]

mgmt_bitlen = (node['bcpc']['networks'][subnet]['management']['cidr'].match /\d+\.\d+\.\d+\.\d+\/(\d+)/)[1].to_i
mgmt_hostaddr = IPAddr.new(node['bcpc']['management']['ip'])<<mgmt_bitlen>>mgmt_bitlen

stor_bitlen = (node['bcpc']['networks'][subnet]['storage']['cidr'].match /\d+\.\d+\.\d+\.\d+\/(\d+)/)[1].to_i
stor_hostaddr = IPAddr.new(node['bcpc']['management']['ip'])<<stor_bitlen>>stor_bitlen

flot_bitlen = (node['bcpc']['networks'][subnet]['floating']['cidr'].match /\d+\.\d+\.\d+\.\d+\/(\d+)/)[1].to_i
##If we have a full class B, then simply leave the 3rd octet alone and use the 4th octet from mgmt ip
#Then we leave the rest of the float Ips for the VMs
flot_bitlen = 24 if flot_bitlen == 16
flot_hostaddr = IPAddr.new(node['bcpc']['management']['ip'])<<flot_bitlen>>flot_bitlen

node.default['bcpc']['storage']['ip'] = ((IPAddr.new(node['bcpc']['networks'][subnet]['storage']['cidr'])>>(32-stor_bitlen)<<(32-stor_bitlen))|stor_hostaddr).to_s
node.default['bcpc']['floating']['ip'] = ((IPAddr.new(node['bcpc']['networks'][subnet]['floating']['cidr'])>>(32-flot_bitlen)<<(32-flot_bitlen))|flot_hostaddr).to_s
node.default['bcpc']['floating']['cidr'] = node['bcpc']['networks'][subnet]['floating']['cidr']

node.save rescue nil
