# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# This is a Vagrantfile to automatically provision a bootstrap node
# with a Chef server.
#
# See http://www.vagrantup.com/ for info on Vagrant.
#

require 'json'

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
  $stderr.puts "Found #{local_file}, including"
  require local_file
end

#
# Since we run vagrant commands from ~/chef-bcpc and from
# ~/chef-bcpc/vbox directory, finding correct location for environment
# file is important.
#
# To set the base_dir correct we check if we are inside "vbox"
# directory or not and act accordingly
#

base_dir = if File.basename(File.expand_path('.')) == 'vbox'
             File.expand_path('../environments')
           else
             File.expand_path('./environments')
           end

$stderr.puts "Base directory is : #{base_dir}"

json_file = Dir[File.join("#{base_dir}/../environments/", '*.json')]

if json_file.empty?
  $stderr.puts 'No environment file found to parse. ' \
    'Please make sure at least one environment file exists.'
  exit
end

if json_file.length > 1
  $stderr.puts 'More than one environment file found.'
  exit
end

chef_env = JSON.parse(File.read(json_file.join(',')))

cluster_environment = chef_env['name']

bootstrap_hostname =
  chef_env['override_attributes']['bcpc']['bootstrap']['hostname']

bootstrap_domain =
  chef_env['override_attributes']['bcpc']['domain_name']

# We rely on global variables to deal with Vagrantfile scoping rules.
# rubocop:disable Style/GlobalVars
$bach_local_environment = cluster_environment
$bach_local_mirror = nil

Vagrant.configure('2') do |config|
  config.vm.define :bootstrap do |bootstrap|
    bootstrap.vm.hostname = "#{bootstrap_hostname}.#{bootstrap_domain}"

    bootstrap.vm.network(:private_network,
                         ip: '10.0.100.3',
                         netmask: '255.255.255.0',
                         adapter_ip: '10.0.100.2')

    bootstrap.vm.network(:private_network,
                         ip: '172.16.100.3',
                         netmask: '255.255.255.0',
                         adapter_ip: '172.16.100.2')

    bootstrap.vm.network(:private_network,
                         ip: '192.168.100.3',
                         netmask: '255.255.255.0',
                         adapter_ip: '192.168.100.2')

    if File.basename(File.expand_path('.')) == 'vbox'
      bootstrap.vm.synced_folder '../', '/chef-bcpc-host'
    else
      bootstrap.vm.synced_folder './', '/chef-bcpc-host'
    end

    # set up repositories
    if $bach_local_mirror
      bootstrap.vm.provision :shell, inline: <<-EOH
        sed -i s/archive.ubuntu.com/#{$bach_local_mirror}/g /etc/apt/sources.list
        sed -i s/security.ubuntu.com/#{$bach_local_mirror}/g /etc/apt/sources.list
        sed -i s/^deb-src/\#deb-src/g /etc/apt/sources.list
      EOH
    end
  end

  config.vm.box = 'trusty64'
  config.vm.box_url = 'trusty-server-cloudimg-amd64-vagrant-disk1.box'

  memory = ENV['BOOTSTRAP_VM_MEM'] || '4096'
  cpus = ENV['BOOTSTRAP_VM_CPUs'] || '1'

  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    vb.gui = false
    vb.name = bootstrap_hostname.to_s
    vb.customize ['modifyvm', :id, '--nictype2', '82543GC']
    vb.customize ['modifyvm', :id, '--memory', memory]
    vb.customize ['modifyvm', :id, '--cpus', cpus]
    vb.customize ['modifyvm', :id, '--largepages', 'on']
    vb.customize ['modifyvm', :id, '--nestedpaging', 'on']
    vb.customize ['modifyvm', :id, '--vtxvpid', 'on']
    vb.customize ['modifyvm', :id, '--hwvirtex', 'on']
    vb.customize ['modifyvm', :id, '--ioapic', 'on']
  end
end
