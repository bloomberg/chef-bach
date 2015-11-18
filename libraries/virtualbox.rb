# See ROM-O-MATIC.md for instruction on how to generate a new gPXE ROM.
def pxe_rom_path
  File.join(Chef::Config.file_cache_path, 'gpxe.rom')
end

# Turns VirtualBox VM data into a Ruby hash.
def get_vbox_vm_info(name:)
  require 'mixlib/shellout'

  c = Mixlib::ShellOut.new('vboxmanage', 'showvminfo',
                           name, '--machinereadable')
  c.run_command

  if c.status.success?
    tuples = c.stdout.split("\n")
      .map{ |element| element.split("=") }
      .flatten
      .map{ |string| string.gsub(/^"/, '').gsub(/"$/, '') }
    Hash[*tuples]
  else
    nil
  end
end

def create_vbox_vm(name:)
  if get_vbox_vm_info(name: name).nil?
    system('vboxmanage', 'createvm',
           '--name', name,
           '--ostype', 'Ubuntu_64',
           '--register')
  end

  system('vboxmanage', 'modifyvm', name,
         '--memory', node[:bach][:cluster][:demo][:memory].to_s)

  system('vboxmanage', 'modifyvm', name,
         '--cpus', node[:bach][:cluster][:demo][:cpus].to_s)

  # 
  # We need to find out which host ifs are in use for each of the
  # three cluster networks (management, storage, floating).  The
  # bootstrap node has a leg on each of these networks, so its vm info
  # will contain the host interface names.
  #
  # The first interface on a vagrant box is always nat, so our three
  # cluster networks are tied to the second, third, and fourth
  # adapters on the bootstrap vm.
  #
  
  hostonly_adapter_keys = ["hostonlyadapter2",
                           "hostonlyadapter3",
                           "hostonlyadapter4"]

  bootstrap_info = get_vbox_vm_info(name: bootstrap_vm_name)

  hostonly_adapter_keys.each do |key|
    raise "no host interface (vboxnetn) found for #{key}!" unless bootstrap_info[key]
  end

  iface1, iface2, iface3 =
    bootstrap_info.values_at(*hostonly_adapter_keys)

  system('vboxmanage', 'modifyvm', name,
         '--nic1', 'hostonly',
         '--hostonlyadapter1', iface1,
         '--nictype1', '82543gc')
  
  system('vboxmanage', 'modifyvm', name,
         '--nic2', 'hostonly',
         '--hostonlyadapter2', iface2,
         '--nictype2', '82543gc')
  
  system('vboxmanage', 'modifyvm', name,
         '--nic3', 'hostonly',
         '--hostonlyadapter3', iface3,
         '--nictype3', '82543gc')

  system('vboxmanage', 'setextradata', name,
         'vboxinternal/devices/pcbios/0/config/lanbootrom',
         pxe_rom_path)

  system('vboxmanage', 'modifyvm', name,
         '--boot1', 'disk',
         '--boot2', 'net')

  target_controller_name = "SATA controller for BACH disks"

  current_controller_name =
    get_vbox_vm_info(name: name).fetch('storagecontrollername0') rescue nil
   
  unless(target_controller_name == current_controller_name)
    system('vboxmanage', 'storagectl', name,
           '--name', target_controller_name,
           '--add', 'sata')
  end

  # hardware accelerated virtualization options.
  system('vboxmanage', 'modifyvm', name,
         '--hwvirtex', 'on',
         '--ioapic', 'on',
         '--largepages', 'on',
         '--vtxvpid', 'on')

  # serial ports.
  system('vboxmanage', 'modifyvm', name,
         '--uart1', '0x3F8', '4')
  system('vboxmanage', 'modifyvm', name,
         '--uartmode1', 'server', "/tmp/#{}{vm}-serial-ttyS0")

  require 'pathname'
  vm_path = Pathname.new(get_vbox_vm_info(name: name)['CfgFile']).dirname

  ['sda', 'sdb','sdc','sdd','sde'].each_with_index do |dev,i|
    disk_path = File.join(vm_path, "#{name}-#{dev}.vdi")

    unless File.exists?(disk_path)
      system('vboxmanage', 'createhd',
             '--filename', disk_path,
             '--size', (20 * 1024).to_s)
    end

    system('vboxmanage', 'storageattach', name, 
           '--storagectl', target_controller_name,
           '--port', (i + 1).to_s, 
           '--device', 0.to_s, 
           '--type', 'hdd', 
           '--medium', disk_path)
  end
end

def destroy_vbox_vm(name:)
end
