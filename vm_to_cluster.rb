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

def parse_options
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: vm_to_cluster.rb [options]'

    opts.on('-q', '--[no-]quiet', 'Whether to exit on missing VMs') do |s|
      options[:silent] = s
    end
  end.parse!
  options
end

# data_check runs data validation across all entry lines
# Input: cluster_lines
# Output: Hash of:
#           Array lines: each element is a Hash of:
#             line: raw line
#             message: offset as value
#           Array messages: array of errors matched to offset
def data_check(cluster_lines)
  errors = ['Found bogus MAC address']
  # check for failed MAC addresses
  failed_macs = cluster_lines.select { |l| l[1].eql?(BOGUS_VB_MAC) }\
                             .collect { |l| {line: l.join(' '), message: 0} }
  {
    lines: failed_macs,
    messages: failed_macs.empty? ? nil : ['Found bogus MAC address']
  }
end

if File.basename(__FILE__) == File.basename($PROGRAM_NAME)
  options = parse_options
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
    # HACK: We have not edited cluster.txt yet, but may have 
    # forced the VMs to have a ${BACH_CLUSTER_PREFIX}-
    # when we generated VM_LIST in vbox_create.sh
    if ENV['BACH_CLUSTER_PREFIX'] != '' then
      e[:hostname] = "#{ENV['BACH_CLUSTER_PREFIX']}-#{e[:hostname]}"
    end
    # use a bogus MAC for not yet created VMs in case it gets handed to Cobbler
    # otherwise use the MAC as passed in
    mac = vms.key?(e[:hostname]) ? virtualbox_mac(e[:hostname]) : \
      virtualbox_vm?(e) ? BOGUS_VB_MAC : e[:mac]
    ip = IPAddr.new(management_net.to_i + \
      IPAddr.new("#{e[:ip_address]}/32").to_i - \
      IPAddr.new("#{e[:ip_address]}/24").to_i, Socket::AF_INET).to_s

    # set to EFI or legacy Cobbler type as desired for VMs
    profile = ! vms.key?(e[:hostname]) ?  e[:cobbler_profile] : \
      virtualbox_bios(e[:hostname]).eql?('EFI') ? \
      EFI_COBBLER_PROFILE : BIOS_COBBLER_PROFILE

    [e[:node_id], e[:hostname], mac, ip, e[:ilo_address], profile, e[:dns_domain], e[:runlist]]
  end

  # check to see if we should raise an error
  unless options[:silent]
    failed_data = data_check(cluster_lines)
    raise "Malformed cluster.txt or system not configured correctly!\n" +
          "#{failed_data}" unless failed_data[:lines].empty?
  end

  f = File.open('cluster.txt', 'w')
  # ensure we write a trailing newline
  f.write(cluster_lines.map { |l| l.join(' ') }.join("\n") + "\n")
  f.close
end
