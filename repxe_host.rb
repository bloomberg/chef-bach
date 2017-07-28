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
#  4. Run 'bundle exec ./repxe_host.rb -m <hostname>' to begin the process.
#     To run on a brand new node that doesn't need to be shut down first, run:
#     'bundle exec ./repxe_host.rb -m <hostname> -s'
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
require 'English'
require 'mixlib/shellout'
require 'pry'
require 'timeout'
require 'optparse'

require_relative 'lib/cluster_data'
include BACH::ClusterData

def cluster_assign_roles(environment, type, entry=nil)
  types = %w[basic hadoop kafka]
  unless types.include?(type.to_s.downcase)
    raise "#{type} is not one of #{types.join(',')} !"
  end

  #
  # We use system() instead of Mixlib::ShellOut specifically so that the
  # child process re-uses our STDOUT/STDERR.
  #
  # TODO: replace with IO::popen3
  #
  if entry.nil?
    system('sudo', './cluster-assign-roles.sh',
           environment, type.to_s.downcase.capitalize)
  else
    system('sudo', './cluster-assign-roles.sh',
           environment, type.to_s.downcase.capitalize, entry[:hostname])
  end

  # Why doesn't this raise an error?
  puts 'cluster-assign-roles.sh failed!' unless $CHILD_STATUS.success?
end

def restart_chef_server
  c = Mixlib::ShellOut.new('sudo', 'chef-server-ctl', 'restart')
  c.run_command

  raise 'Failed to restart chef-server' unless c.status.success?

  puts 'restarted chef-server'
end

def cobbler_unenroll(entry)
  c = Mixlib::ShellOut.new('sudo', 'cobbler', 'system', 'remove',
                           '--name', entry[:hostname])
  c.run_command

  raise "Failed to un-enroll #{entry[:hostname]}!" unless c.status.success?

  puts "Un-enrolled #{entry[:hostname]} from cobbler"
end

def cobbler_enroll(entry)
  c = Mixlib::ShellOut.new('sudo', 'cobbler', 'system', 'add',
                           '--name', entry[:hostname],
                           '--hostname', fqdn(entry),
                           '--profile', entry[:cobbler_profile],
                           '--ip-address', entry[:ip_address],
                           '--interface=eth0',
                           '--mac', corrected_mac(entry))

  c.run_command

  unless c.status.success?
    raise "Failed to enroll #{entry[:hostname]}!"
  end

  puts "Enrolled #{entry[:hostname]} in cobbler"
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

  unless vault_command.status.success?
    raise 'Could not retrieve cobbler password!\n' +
          vault_command.stdout + '\n' +
          vault_command.stderr
  end

  JSON.parse(vault_command.stdout)['root-password']
end

def cobbler_sync
  c = Mixlib::ShellOut.new('sudo', 'cobbler', 'sync')
  c.run_command
  raise 'Failed to sync cobbler' unless c.status.success?
end

# Removes the Chef server objects and SSH known_hosts entries for a host.
# Takes a hash from cluster.txt as sole argument.
def delete_node_data(entry)
  ['client',
   'node'].each do |object|
    Mixlib::ShellOut.new('sudo', 'knife',
                         object, 'delete',
                         entry[:fqdn], '--yes').run_command
  end

  # Running knife with sudo can set the permissions to root:root.
  # We need to correct the permissions before running ssh-keygen.
  Mixlib::ShellOut.new('sudo', 'chown',
                       `whoami`.chomp,
                       "#{ENV['HOME']}/.ssh/known_hosts").run_command

  [entry[:fqdn],
   entry[:ip_address],
   entry[:hostname]].each do |ssh_name|
    del = Mixlib::ShellOut.new('ssh-keygen', '-R', ssh_name)
    del.run_command
    unless del.status.success?
      raise "Failed to delete SSH key for #{ssh_name}: #{del.stderr}"
    end
  end

  puts "Deleted SSH fingerprints and Chef objects for #{entry[:hostname]}"
end

def restart_host(entry)
  # if is_virtualbox_vm?(entry)
  #   # If it's a virtualbox VM, prompt the user to do it for us.
  #   puts 'Please reboot ' + entry[:hostname] + ', then hit enter'
  #   STDIN.gets
  # else
  #   # Otherwise, reach out via IPMI
  #   raise "IPMI is unimplemented!"
  # end

  puts 'Please reboot ' + entry[:hostname] + ' ' \
       'into pxe-boot mode, then hit enter'
  STDIN.gets
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
  ssh_options = { auth_methods: ['password'],
                  config: false,
                  password: cobbler_root_password,
                  user_known_hosts_file: '/dev/null' }
  prompts = { number_of_password_prompts: 0 }
  options = {}
  config =  { log_level: :warn }

  ssh_transport =
    Chef::Provisioning::Transport::SSH.new(entry[:ip_address],
                                           'ubuntu',
                                           ssh_options.merge(prompts),
                                           options,
                                           config)

  #
  # If it takes more than half an hour for the node to respond,
  # something is really broken.
  #
  # This will make 60 attempts with a 1 minute sleep between attempts,
  # or timeout after 61 minutes.
  #
  Timeout.timeout(3720) do
    max = 60
    1.upto(max) do |idx|
      break if ssh_transport.available?

      puts "Waiting for #{entry[:hostname]} to respond to SSH " \
        "on #{entry[:ip_address]} (attempt #{idx}/#{max})"
      sleep 60
    end
  end

  if ssh_transport.available?
    puts "Reached #{entry[:hostname]} via SSH, continuing"
    true
  else
    raise "Failed to reach #{entry[:hostname]} via SSH!"
  end
end

# Find the Chef environment
def find_chef_env
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
                         '-F', 'json')

  env_command.run_command

  unless env_command.status.success?
    raise 'Could not retrieve Chef environment!\n' +
          env_command.stdout + '\n' +
          env_command.stderr
  end

  JSON.parse(env_command.stdout)['chef_environment']
end

def get_mounted_disks(chef_env, vm_entry)
  c = Mixlib::ShellOut.new('./nodessh.sh',
                           chef_env,
                           vm_entry[:hostname],
                           'df -h')
  c.run_command
  disks = c.stdout.split("\n")
  disks = disks[1..disks.length]

  # return all disks mapped to /disk/#
  disks.map do |disk|
    disk.split(' ')[-1]
  end.map do |disk|
    %r{\/disk\/\d+}.match(disk).nil? ? nil : disk
  end.compact
end

def unmount_disks(chef_env, vm_entry)
  puts 'Unmounting disks.'
  get_mounted_disks(chef_env, vm_entry).each do |disk|
    puts 'unmounting ' + disk
    c = Mixlib::ShellOut.new('./nodessh.sh',
                             chef_env,
                             vm_entry[:hostname],
                             'umount ' + disk,
                             'sudo')
    c.run_command
    if c.status.success?
      puts 'Unmounted ' + disk
    else
      raise 'Could not unmount ' + disk + ' ' + c.stdout + '\n' + c.stderr
    end
  end
end

def confirm_chef_client_down(chef_env, vm_entry)
  #
  # If it takes more than 2 minutes
  # something is really broken.
  #
  # This will make 30 attempts with a 1 minute sleep between attempts,
  # or timeout after 31 minutes.
  #
  command = 'ps -ef | grep chef-client | grep -v grep'
  Timeout.timeout(120) do
    max = 5
    1.upto(max) do |idx|
      c = Mixlib::ShellOut.new('./nodessh.sh',
                               chef_env,
                               vm_entry[:hostname],
                               command)
      c.run_command
      if c.exitstatus == 1 && c.stdout == ''
        puts 'chef client is down'
        break
      else
        puts "Waiting for chef to go down (attempt #{idx}/#{max})"
        sleep 30
      end
    end
  end
end

def kill_chef_client(chef_env, vm_entry)
  puts 'Stopping chef-client'
  [
    'service chef-client stop ',
    'pkill -f chef-client'
  ].each do |command|
    c = Mixlib::ShellOut.new('./nodessh.sh',
                             chef_env,
                             vm_entry[:hostname],
                             command,
                             'sudo')
    c.run_command
  end
  confirm_chef_client_down(chef_env, vm_entry)
  puts 'Chef client is down'
end

def start_chef_client(chef_env, vm_entry)
  puts 'Starting chef-client'
  c = Mixlib::ShellOut.new('./nodessh.sh',
                           chef_env,
                           vm_entry[:hostname],
                           'service chef-client start',
                           'sudo')
  c.run_command
  if c.status.success?
    puts 'Chef client started.'
  else
    puts 'Chef client did not start successfully: ' +
         c.stdout + '\n' + c.stderr
  end
end

def run_chef_client(chef_env, vm_entry, params = ' ')
  puts 'Running chef-client'
  c = Mixlib::ShellOut.new('./nodessh.sh',
                           chef_env,
                           vm_entry[:hostname],
                           'chef-client',
                           params,
                           'sudo')
  c.run_command
  if c.status.success?
    puts 'Chef client ran.'
  else
    puts 'Chef client did not run successfully: ' +
         c.stdout + '\n' + c.stderr
  end
end

def stop_all_services(chef_env, vm_entry)
  puts 'Stopping services.'
  [
    'carbon-relay',
    'carbon-aggregator',
    'carbon-cache',
    'apache2', # graphite-web
    'jmxtrans',
    'hbase-regionserver',
    'hbase-master',
    'hadoop-hdfs-datanode',
    'hadoop-httpfs',
    'hadoop-yarn-nodemanager',
    'hadoop-hdfs-journalnode',
    'hadoop-hdfs-namenode',
    'hadoop-hdfs-zkfc',
    'haproxy'
  ].each do |service|
    c = Mixlib::ShellOut.new('./nodessh.sh',
                             chef_env,
                             vm_entry[:hostname],
                             'service ' + service + ' stop',
                             'sudo')
    c.run_command
    if c.status.success?
      puts 'Stopped ' + service
    else
      puts 'Could not stop service ' +
           service + ' ' + c.stdout + '\n' + c.stderr
    end
  end
end

def shutdown_box(chef_env, vm_entry)
  c = Mixlib::ShellOut.new('./nodessh.sh',
                           chef_env,
                           vm_entry[:hostname],
                           'shutdown -h now',
                           'sudo')
  c.run_command
  if !c.status.success?
    raise 'Could not shut down host ' +
          vm_entry[:hostname] + '\n' + c.stdout + '\n' + c.stderr
  else
    puts 'Host has been shut down.'
  end
end

# Graceful shutdown - bring down all services, unmount disks, shutdown
def graceful_shutdown(chef_env, vm_entry)
  puts 'Running graceful shutdown of ' + vm_entry[:hostname]
  kill_chef_client(chef_env, vm_entry)
  stop_all_services(chef_env, vm_entry)
  unmount_disks(chef_env, vm_entry)
  shutdown_box(chef_env, vm_entry)
end

#
# This conditional allows us to use the methods into irb instead of
# invoking the script from a UNIX shell.
#
if __FILE__ == $PROGRAM_NAME
  options = { shutdown: true, newmachine: false, down: false }

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: repxe_host.rb [options]'

    opts.on('-s', '--skipShutdown', 'Skip Shutdown') do
      options[:shutdown] = false
    end

    opts.on('-n', '--newmachine', 'PXE boot a new machine') do
      options[:newmachine] = true
      options[:shutdown] = false
    end

    opts.on('-m', '--machine machine', 'Machine') do |machine|
      options[:machine] = machine
      puts 'found an option for machine with value ' + machine
    end

    opts.on('-d', '--down', 'Just bring the machine down') do
      options[:down] = true
      options[:shutdown] = true
    end

    opts.on('-h', '--help', 'Displays Help') do
      puts opts
      exit
    end
  end

  parser.parse!

  if options[:machine].nil?
    puts parser
    exit(-1)
  end

  vm_entry = get_entry(options[:machine])

  if vm_entry.nil?
    puts "'#{options[:machine]}' was not found in cluster.txt!"
    exit(-1)
  end

  puts 'Repxe script started for node ' + options[:machine]
  chef_env = find_chef_env

  graceful_shutdown(chef_env, vm_entry) if options[:shutdown]

  if options[:down]
    puts 'Machine has been shut down.  Exiting.'
    exit
  end

  unless options[:newmachine]
    delete_node_data(vm_entry)
    rotate_vault_keys
    cobbler_unenroll(vm_entry)
  end

  # HACK: restart to free up memory.  Chef server 11 has a memory leak.
  restart_chef_server
  cobbler_enroll(vm_entry)
  cobbler_sync
  restart_host(vm_entry)
  wait_for_host(vm_entry)
  cluster_assign_roles(chef_env, :basic, vm_entry)
  # HACK: vas cookbook has issues, so sleep and try again
  sleep(360)
  cluster_assign_roles(chef_env, :basic, vm_entry)
  rotate_vault_keys
  refresh_vault_keys
  # HACK: Forces convergence of certain ohai attributes
  run_chef_client(chef_env, vm_entry, '-r \'bach_hadoop_wrapper,bcpc::chef_vault_install\'')
  cluster_assign_roles(chef_env, :hadoop, vm_entry)
  # HACK: sometimes rechefing seems to do the trick...
  run_chef_client(chef_env, vm_entry)
  start_chef_client(chef_env, vm_entry)
end
