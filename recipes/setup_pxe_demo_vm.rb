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

end
