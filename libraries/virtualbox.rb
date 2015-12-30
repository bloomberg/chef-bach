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

  hostonly_adapter_keys.each do |adapter_name|
    unless bootstrap_info.has_key?(adapter_name)
      raise "no host interface (vboxnetN) found for #{adapter_name}!"
    end
  end

  adapters = bootstrap_info.values_at(*hostonly_adapter_keys)

  system('vboxmanage', 'modifyvm', name,
         '--nic1', 'hostonly',
         '--hostonlyadapter1', adapters[0],
         '--nictype1', '82543gc')
  
  system('vboxmanage', 'modifyvm', name,
         '--nic2', 'hostonly',
         '--hostonlyadapter2', adapters[1],
         '--nictype2', '82543gc')
  
  system('vboxmanage', 'modifyvm', name,
         '--nic3', 'hostonly',
         '--hostonlyadapter3', adapters[2],
         '--nictype3', '82543gc')

  system('vboxmanage', 'modifyvm', name,
         '--boot1', 'disk',
         '--boot2', 'net')

  target_controller_name = "SATA controller for BACH disks"

  current_controller_name =
    get_vbox_vm_info(name: name).fetch('storagecontrollername0') rescue nil
   
  unless(target_controller_name == current_controller_name)
    system('vboxmanage', 'storagectl', name,
           '--name', target_controller_name,
           '--portcount', '5',
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

def start_vbox_vm(name:)
  info = get_vbox_vm_info(name: name)
  raise "Cannot start non-existent VM: #{name}" if info.nil?
  if info['VMState'] != 'running'
    require 'mixlib/shellout'

    c = Mixlib::ShellOut.new('vboxmanage', 'startvm', name,
                             '--type', 'headless')
    c.run_command

    if c.status.success?
      Chef::Log.warn("Started #{name}.")
    else
      raise "Failed to start VM:\n#{c.inspect}"
    end
  end
  return true
end

def ssh_check(ip:, username:, password:)
  require 'net/ssh'
  begin
    Net::SSH.start(ip, username,
                   :auth_methods => ['password'],
                   :config => false,
                   :password => password,
                   :timeout => 60,
                   :user_known_hosts_file => '/dev/null') do |ssh|
      ssh.exec!('ls')
    end
  rescue Net::SSH::Disconnect, Errno::ECONNREFUSED
    return false
  end
end
