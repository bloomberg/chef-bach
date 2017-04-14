#!/usr/bin/env ruby

#
# Script to help making a cluster definition file (cluster.txt) from
# the current VMs known by VirtualBox -- eg after vbox_create.sh. This
# is intended to be run on the hypervisor as it relies on using the
# VBoxManage tool
#
# cluster.txt can be used by the cluster-*.sh tools for various
# cluster automation tasks, see cluster-readme.txt
#

require 'ipaddr'
require 'json'
require 'set'
require 'chef'
require_relative 'lib/cluster_data.rb'
require_relative 'lib/hypervisor_node.rb'

include BACH::ClusterData
include BACH::ClusterData::HypervisorNode

#
# Updates MAC address based on VirtualBox
# Modifies IP addresses to be in the network as specified in the
# environment file
#
chef_env = JSON.parse(File.read(chef_environment_path))
rack = chef_env['override_attributes']['bcpc']['networks'].keys.first
network_json = chef_env['override_attributes']['bcpc']['networks'][rack]
management_net = \
  IPAddr.new(network_json['management']['cidr'] || '10.0.100.0/24')

vms = virtualbox_vms
entries = parse_cluster_txt(cluster_txt)

cluster_lines = entries.map do |e|
  # use a bogus MAC for not yet created VMs incase it gets handed to Cobbler
  mac = vms.key?(e[:hostname]) ? virtualbox_mac(e[:hostname]) : \
    'c0:ff:33:c0:ff:33'
  ip = IPAddr.new(management_net.to_i + \
    IPAddr.new("#{e[:ip_address]}/32").to_i - \
    IPAddr.new("#{e[:ip_address]}/24").to_i, Socket::AF_INET).to_s

  [e[:hostname], mac, ip, e[:ilo_address], e[:cobbler_profile], e[:dns_domain], e[:runlist]].join(' ')
end

puts cluster_lines.join("\n")
