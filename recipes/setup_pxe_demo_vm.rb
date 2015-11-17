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

# do i use vagrant to stand up the VM? if i do, what does it expect to find? no.  vagrant expects a lot of stuff and i don't want to write a driver like steve

# See ROM-O-MATIC.md for instruction on how to generate a new gPXE ROM.
pxe_rom_path = File.join(Chef::Config.file_cache_path, 'gpxe.rom')
cookbook_file pxe_rom_path do
  source 'gpxe-1.0.1-80861004.rom'
  mode 0444
end

def get_vbox_vm_info(name:)
  require 'mixlib/shellout'
  c = Mixlib::ShellOut.new('vboxmanage', 'showvminfo',
                           name, '--machinereadable')
  c.run_command!
  tuples = c.stdout.split("\n")
    .map{ |element| e.split("=") }
    .flatten
    .map{ |string| string.gsub(/^"/, '').gsub(/"$/, '') }
  Hash[*tuples]
end

def create_vbox_vm(name:)
  system('vboxmanage', 'createvm',
         '--name', name,
         '--ostype', 'Ubuntu_64',
         '--register')

  system('vboxmanage', 'modifyvm', name,
         '--memory', node[:bach][:cluster][:demo][:memory])

  system('vboxmanage', 'modifyvm', name,
         '--cpus', node[:bach][:cluster][:demo][:cpus])

  system('vboxmanage', 'modifyvm', name,
         '--cpus', node[:bach][:cluster][:demo][:cpus])

  #
  # The first interface on a vagrant box is always NAT, so our three
  # cluster networks are the second, third, and fourth adapters on the
  # bootstrap VM.
  #
  iface1, iface2, iface3 =
    get_vbox_vm_info(name: bootstrap_vm_name).values_at("hostonlyadapter2",
                                                        "hostonlyadapter3",
                                                        "hostonlyadapter4")

  system('vboxmanage', 'modifyvm', name,
         '--nic1', 'hostonly',
         '--hostonlyadapter1', iface1,
         '--nictype', '82543GC')
  
  system('vboxmanage', 'modifyvm', name,
         '--nic2', 'hostonly',
         '--hostonlyadapter2', iface2,
         '--nictype', '82543GC')
  
  system('vboxmanage', 'modifyvm', name,
         '--nic3', 'hostonly',
         '--hostonlyadapter3', iface3,
         '--nictype', '82543GC')

  system('vboxmanage', 'setextradata', name,
         'VBoxInternal/Devices/pcbios/0/Config/LanBootRom',
         pxe_rom_path)

  system('vboxmanage', 'storagectl', name,
         '--name', "SATA Controller",
         '--add', 'sata')
end

def destroy_vbox_vm(name:)
end
