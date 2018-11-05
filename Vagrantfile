#
# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# This is a Vagrantfile to provision blank Ubuntu images for use with
# chef-bach.
#
# See http://www.vagrantup.com/ for info on Vagrant.
#

require 'json'
require 'ipaddr'
prefix = File.basename(File.expand_path('.')) == 'vbox' ? '../' : './'
require_relative "#{prefix}lib/cluster_data"
require_relative "#{prefix}lib/hypervisor_node"

include BACH::ClusterData
include BACH::ClusterData::HypervisorNode

#
# You can override parts of the vagrant config by creating a
# 'Vagrantfile.local.rb'
#
# (You may find this useful for SSL certificate injection.)
#
local_file =
  if File.basename(File.expand_path('.')) == 'vbox'
    File.expand_path('../Vagrantfile.local.rb')
  else
    "#{__FILE__}.local.rb"
  end

if File.exist?(local_file)
  if ENV['BACH_DEBUG']
    $stderr.puts "Found #{local_file}, including"
  end
  require local_file
end

Vagrant.configure('2') do |config|
  config.vm.box = 'bento/ubuntu-14.04'

  # These memory and CPU settings are used for all cluster nodes, and the bootstrap as well.
  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.cpus = ENV.fetch 'CLUSTER_VM_CPUs', 2
    vb.memory = ENV.fetch 'CLUSTER_VM_MEM', 8192
  end

  config.vm.define 'bootstrap' do |bs|
    bs.vm.hostname = 'bootstrap.bcpc.example.com'

    # FIXME calculate subnets from Test-Laptop.json
    bs.vm.network :private_network, ip: '10.0.100.3', netmask: '255.255.255.0'
  end

  #
  # Parse the cluster.txt selected by shell scripts (either Hadoop or
  # Kafka) and generate matching VMs.
  #
  parse_cluster_txt(cluster_txt).each do |vm_definition|
    config.vm.define vm_definition[:hostname] do |vboxvm|
      vboxvm.vm.hostname = vm_definition[:hostname]
      vboxvm.vm.network :private_network,
                        ip: vm_definition[:ip_address],
                        netmask: '255.255.255.0'
      vboxvm.vm.provider :virtualbox do |vb|
        4.times do |i|
          port = i + 2 # ubuntu/trusty64 has port 0 for the root disk
          vb.customize ['createhd',
                        '--filename', ".vagrant/machines/#{vm_definition[:hostname]}/" \
                                      "#{vm_definition[:hostname]}-disk#{i}.vdi",
                        '--size', (40 * 1024)]

          # "SATA Controller" is the prebuilt controller in bento/ubuntu-14.04
          vb.customize ['storageattach', :id,
                        '--storagectl', 'SATA Controller',
                        '--port', port,
                        '--type', 'hdd',
                        '--medium', ".vagrant/machines/#{vm_definition[:hostname]}/" \
                                    "#{vm_definition[:hostname]}-disk#{i}.vdi"]
        end
      end
    end
  end
end
