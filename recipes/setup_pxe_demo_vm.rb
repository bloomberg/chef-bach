# Don't use proxies to talk to the bootstrap node's chef server.
Chef::Config['no_proxy'] = "#{bootstrap_fqdn},#{bootstrap_ip}"
ENV['no_proxy'] = Chef::Config['no_proxy']
log "Resetting no_proxy variables to: #{Chef::Config['no_proxy']}"

require 'chef/provisioning/ssh_driver'

# Reminder: I can't provision external DNS on the bootstrap without knowing macs for a demo environment.  Ugly.  I guess "use a real external DNS" is gonna be a config parameter.

# vms:
# get macs
# create a virtualbox vm w/ mandated macs & pxe rom
# register in cobbler
# boot the sucker
# wait until it answers on 22
# use ssh profivisioning

# hw:
# get macs
# register in cobbler
# boot the sucker
# wait until it answers on 22
# use ssh profivisioning

# See ROM-O-MATIC.md for instruction on how to generate a new gPXE ROM.
cookbook_file pxe_rom_path do
  source 'gpxe-1.0.1-80861004.rom'
  mode 0660
end

worker_node_count = node[:bach][:cluster][:node_count].to_i
total_node_count = worker_node_count + 2

# We will use the vagrant driver to execute cobbler registrations on the bootstrap VM.
# To do: use SSH driver, get credentials out of the data bags.
require 'chef/provisioning/vagrant_driver'
with_driver 'vagrant'

1.upto(total_node_count).each do |n|
  vm_name = "bach-vm#{n}-b#{build_id}"
  vm_mgmt_ip = "10.0.101." + (3 + n).to_s
  vm_storage_ip = "10.0.101." + (19 + n).to_s
  vm_floating_ip = "10.0.101." + (35 + n).to_s
  my_netmask = '255.255.255.240'

  ruby_block "#{vm_name}-create" do
    block do
      create_vbox_vm(name: vm_name)
    end
  end

  machine_execute "#{vm_name}-cobbler-remove" do    
    machine bootstrap_fqdn
    chef_server chef_server_config_hash
    command "cobbler system remove --name=#{vm_name}"
  end

  machine_execute "#{vm_name}-cobbler-add" do    
    machine bootstrap_fqdn
    chef_server chef_server_config_hash

    command lazy {
      mac_address = get_vbox_vm_info(name: vm_name)
        .fetch('macaddress1').scan(/../).join(':')

      "cobbler system add --name=#{vm_name} " +
        "--hostname=#{fqdn_for(vm_name)} " +
        "--profile=bcpc_host " +
        "--ip-address=#{vm_mgmt_ip} " +
        "--mac=#{mac_address}"
    }
  end
  
  machine_execute "#{vm_name}-cobbler-sync" do    
    machine bootstrap_fqdn
    chef_server chef_server_config_hash
    command 'cobbler sync'
  end
end
