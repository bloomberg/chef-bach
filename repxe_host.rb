#!/usr/bin/env ruby
#
# repxe_host.rb
#
# This script coordinates the re-installation and re-chefing of an
# existing host.
#
# Provisos:
#
#  * It still calls out to c-a-r for the chef bootstrap and re-chefing.
#  * Hosts still have to be manually rebooted.
#
# To use from the command line:
#
#  1. If necessary, configure your local rubygems mirror.
#     Replace 'http://mirror.example.com' with your actual mirror.
#     ```
#     bundle config mirror.https://rubygems.org http://mirror.example.com
#     ```
#
#  2. Run 'bundle install --deployment' on a bootstrap node with
#     access to a rubygems mirror.
#
#  3. If not already using the target bootstrap, sync the updated
#     repository, including 'vendor' directory, to the target
#     bootstrap.
#
#  4. Run 'bundle exec ./repxe_host.rb <hostname>' to begin the process.
#
#  5. When prompted, manually reboot the host, then press enter.
#
# It is also possible to use methods from this script at a ruby REPL
# instead of running the script from a UNIX shell.  To load methods
# into `irb`:
#
#  1. Change to the repo directory.
#
#  2. Verify that dependencies are installed:
#     `bundle list`
#
#  3. Run irb inside the repo directory.
#     `bundle exec irb`
#
#  4. Load this file.
#     `irb(main):001:0> load ./repxe_host.rb`
#

require 'chef/provisioning/transport/ssh'
require 'mixlib/shellout'
require 'pry'
require 'timeout'

def cluster_assign_roles(environment,type,entry=nil)
  types = [ 'basic', 'hadoop', 'kafka' ]
  if(!types.include?(type.to_s.downcase))
    raise "#{type} is not one of #{types.join(",")} !"
  end

  # We use system() instead of Mixlib::ShellOut specifically so that the
  # child process re-uses our STDOUT/STDERR.
  if entry.nil?
    system('sudo', './cluster-assign-roles.sh',
           environment, type.to_s.downcase.capitalize)
  else
    system('sudo', './cluster-assign-roles.sh',
           environment, type.to_s.downcase.capitalize, entry['hostname'])
  end
  if !$?.success?
    raise "cluster-assign-roles.sh failed!"
  end
end

def cobbler_unenroll(entry)
  c = Mixlib::ShellOut.new('sudo', 'cobbler' ,'system', 'remove',
                           '--name', entry['hostname'])
  c.run_command
  if !c.status.success?
    raise "Failed to un-enroll #{entry['hostname']}!"
  end

  puts "Un-enrolled #{entry['hostname']} from cobbler"
end

def cobbler_enroll(entry)
  c = Mixlib::ShellOut.new('sudo', 'cobbler', 'system', 'add',
                           '--name', entry['hostname'],
                           '--hostname', fqdn(entry),
                           '--profile', entry['cobbler_profile'],
                           '--ip-address', entry['ip_address'],
                           '--mac', corrected_mac(entry))
  c.run_command
  if !c.status.success?
    raise "Failed to enroll #{entry['hostname']}!"
  end

  puts "Enrolled #{entry['hostname']} in cobbler"
end

# This is mostly copy/pasted out of BACH-next chef helpers.
def cobbler_root_password      
  require 'json'
  require 'mixlib/shellout'
  
  vault_command =
    Mixlib::ShellOut.new('sudo',
                         'knife', 'vault', 'show',
                         'os', 'cobbler',
                         '-F', 'json',
                         '-p', 'all',
                         '-m', 'client')
  
  vault_command.run_command
  
  if !vault_command.status.success?
    raise 'Could not retrieve cobbler password!\n' +
      vault_command.stdout + '\n' +
      vault_command.stderr
  end
  
  JSON.parse(vault_command.stdout)['root-password']
end
     
def cobbler_sync
  c = Mixlib::ShellOut.new('sudo', 'cobbler', 'sync')
  c.run_command
  if !c.status.success?
    raise "Failed to sync cobbler"
  end
end

def corrected_mac(entry)
  if is_virtualbox_vm?(entry)
    # If it's a virtualbox VM, cluster.txt is wrong, and we need to
    # find the real MAC.
    ping = Mixlib::ShellOut.new('ping', entry['ip_address'], '-c', '1')
    ping.run_command
    if !ping.status.success?
      puts "Ping to #{entry['hostname']} (#{entry['ip_address']}) failed, " +
        "checking ARP anyway."
    end

    arp = Mixlib::ShellOut.new('arp', '-an')
    arp.run_command
    arp_entry = arp.stdout.split("\n")
      .map{|l| l.chomp}
      .select{ |l| l.include?(entry['ip_address']) }
      .first
    match_data =
      /(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w) .ether./.match(arp_entry.to_s)
    if !match_data.nil? && match_data.captures.count == 1
      mac = match_data[1]
      puts "Found #{mac} for #{entry['hostname']} (#{entry['ip_address']})"
      mac
    else
      raise 'Could not find ARP entry for ' +
        "#{entry['hostname']} (#{entry['ip_address']})!"
    end
  else
    # Otherwise, assume cluster.txt is correct.
    entry['mac_address']
  end
end

# Removes the Chef server objects and SSH known_hosts entries for a host.
# Takes a hash from cluster.txt as sole argument.
def delete_node_data(entry)  
  ['client',
   'node'].each do |object|
    Mixlib::ShellOut.new('sudo', 'knife',
                         object, 'delete',
                         fqdn(entry), '--yes').run_command
  end

  # Running knife with sudo can set the permissions to root:root.
  # We need to correct the permissions before running ssh-keygen.
  Mixlib::ShellOut.new('sudo', 'chown',
                       `whoami`.chomp,
                       "#{ENV['HOME']}/.ssh/known_hosts").run_command

  [fqdn(entry),
   entry['ip_address'],
   entry['hostname']].each do |ssh_name|
    del = Mixlib::ShellOut.new('ssh-keygen', '-R', ssh_name)
    del.run_command
    if !del.status.success?
      raise "Failed to delete SSH key for #{ssh_name}: #{del.stderr}"
    end
  end

  puts "Deleted SSH fingerprints and Chef objects for #{entry['hostname']}"
end

def fqdn(entry)
  if(entry['dns_domain'])
    entry['hostname'] + '.' + entry['dns_domain']
  else
    entry['hostname']
  end
end

def get_entry(name)
  parse_cluster_txt.select{ |e| e['hostname'] == name || fqdn(e) == name }.first
end

def is_virtualbox_vm?(entry)
  /^08:00:27/.match(entry['mac_address'])
end

def parse_cluster_txt
  fields = ['hostname',
            'mac_address',
            'ip_address',
            'ilo_address',
            'cobbler_profile',
            'dns_domain',
            'runlist']
  # This is really gross because Ruby 1.9 lacks Array#to_h.
  File.readlines(File.join(repo_dir,"cluster.txt"))
    .map{ |line| Hash[*fields.zip(line.split(' ')).flatten(1)] }
end

def repo_dir
  File.dirname(__FILE__)
end

def restart_host(entry)
  # if is_virtualbox_vm?(entry)
  #   # If it's a virtualbox VM, prompt the user to do it for us.
  #   puts 'Please reboot ' + entry['hostname'] + ', then hit enter'
  #   STDIN.gets;
  # else
  #   # Otherwise, reach out via IPMI
  #   raise "IPMI is unimplemented!"
  # end

  puts 'Please reboot ' + entry['hostname'] + ' into pxe-boot mode, then hit enter'
  STDIN.gets;
end

def rotate_vault_keys
  #
  # There's no error checking here, because it will fail to rotate
  # keys on data bags where the node is an admin.
  #
  # The correct solution would be to rescue from error, scrape a vault
  # name from stderr, then check whether the dead node is an admin on
  # that particular data bag / vault.
  #
  c = Mixlib::ShellOut.new('sudo', 'knife',
                           'vault', 'rotate', 'all', 'keys',
                           '-m', 'client')
  c.run_command
end

# This is mostly copy/pasted out of the BACH-next 'setup_pxe_demo' recipe.
def wait_for_host(entry)
  ssh_options = {:auth_methods => ['password'],
                 :config => false,
                 :password => cobbler_root_password,
                 :user_known_hosts_file => '/dev/null'}
  prompts = {:number_of_password_prompts => 0}
  options = {}
  config =  {:log_level => :warn}

  ssh_transport =
    Chef::Provisioning::Transport::SSH.new(entry['ip_address'],
                                           'ubuntu',
                                           ssh_options.merge(prompts),
                                           options,
                                           config)

  #
  # If it takes more than half an hour for the node to respond,
  # something is really broken.
  #
  # This will make 30 attempts with a 1 minute sleep between attempts,
  # or timeout after 31 minutes.
  #
  Timeout::timeout(1860) do
    max = 30
    1.upto(max) do |idx|
      if !ssh_transport.available?
        puts "Waiting for #{entry['hostname']} to respond to SSH " +
          "on #{entry['ip_address']} (attempt #{idx}/#{max})"
        sleep 60
      end
    end
  end

  if ssh_transport.available?
    puts "Reached #{entry['hostname']} via SSH, continuing"
    true
  else
    raise "Failed to reach #{entry['hostname']} via SSH!"
  end
end  

# Find the Chef environment
def find_chef_env()
  require 'json'
  require 'rubygems'
  require 'ohai'
  require 'mixlib/shellout'
  o = Ohai::System.new
  o.all_plugins

  env_command =
    Mixlib::ShellOut.new('sudo', 'knife',
                         'node', 'show',
                         o[:fqdn] || o[:hostname], '-E',
                         '-f', 'json')
  
  env_command.run_command
  
  if !env_command.status.success?
    raise 'Could not retrieve Chef environment!\n' +
      env_command.stdout + '\n' +
      env_command.stderr
  end
  
  JSON.parse(env_command.stdout)['chef_environment']
end

   
def get_mounted_disks(chef_env, vm_entry)
   c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, vm_entry['hostname'], 'df -h')
   c.run_command
   disks=c.stdout.split("\n") 
   disks = disks[1..disks.length]
   # return all disks mapped to /disk/#
   return disks.map{ |disk| disk.split(" ")[-1]  }.map{|disk| /\/disk\/\d+/.match(disk) == nil ? nil : disk}.compact
end
   
def unmount_disks(chef_env, vm_entry)
   puts 'Unmounting disks.'
   get_mounted_disks(chef_env, vm_entry).each do |disk|
      puts 'unmounting ' + disk
      c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, vm_entry['hostname'], 'umount '+disk, 'sudo')
      c.run_command
      if !c.status.success?
        raise 'Could not unmount ' + disk + ' ' + c.stdout + '\n' + c.stderr
      else
        puts 'Unmounted ' + disk
      end
   end
end

def stop_all_services(chef_env, vm_entry)
  puts 'Stopping services.'
  ['chef-client',
   'jmxtrans',
   'hbase-regionserver', 
   'hadoop-hdfs-datanode',
   'hadoop-httpfs',
   'hadoop-yarn-nodemanager'].each do |service|
      c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, vm_entry['hostname'], 'service ' + service + ' stop', 'sudo')
      c.run_command
      if !c.status.success?
        puts 'Could not stop service ' + service + ' ' + c.stdout + '\n' + c.stderr
      else
        puts 'Stopped ' + service
      end
   
   end
end

def shutdown_box(chef_env, vm_entry)
   c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, vm_entry['hostname'], 'shutdown -h now', 'sudo')
   c.run_command
   if !c.status.success?
     raise 'Could not shut down host ' + vm_entry['hostname'] + '\n' + c.stdout + '\n' + c.stderr
   else
     puts 'Host has been shut down.'
   end
end

# Graceful shutdown - bring down all services, unmount disks, shutdown
def graceful_shutdown(chef_env, vm_entry)
   #stop_all_services(chef_env, vm_entry)
   unmount_disks(chef_env, vm_entry)
   shutdown_box(chef_env, vm_entry)
end
#
# This conditional allows us to use the methods into irb instead of
# invoking the script from a UNIX shell.
#
if __FILE__ == $PROGRAM_NAME
  if ARGV[0].nil?
    puts "Usage: bundle exec ./repxe_host.rb <hostname>"
    exit(-1)
  end

  vm_entry = get_entry(ARGV[0])

  if vm_entry.nil?
    puts "'#{ARGV[0]}' was not found in cluster.txt!"
    exit(-1)
  end

  puts 'Repxe script started for node ' + ARGV[0]
  chef_env = find_chef_env
  graceful_shutdown(chef_env, vm_entry)
  delete_node_data(vm_entry)
  rotate_vault_keys
  cobbler_unenroll(vm_entry)
  cobbler_enroll(vm_entry)
  cobbler_sync
  restart_host(vm_entry)
  wait_for_host(vm_entry)
  cluster_assign_roles(chef_env, :basic, vm_entry)
  rotate_vault_keys
  cluster_assign_roles(chef_env, :hadoop, vm_entry)
end
