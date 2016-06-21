#!/usr/bin/env ruby
#
# uninstall_zabbix.rb
#
# This script coordinates the uninstall of zabbix from the head nodes.
#
# Provisos:
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
#  4. Run 'bundle exec ./uninstall_zabbix.rb -p <mysql root password>
#      ' to begin the process.
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
#     `irb(main):001:0> load ./uninstall_zabbix.rb`
#

require 'chef/provisioning/transport/ssh'
require 'mixlib/shellout'
require 'pry'
require 'timeout'
require 'optparse'
require 'json'
require 'rubygems'
require 'ohai'
require 'mixlib/shellout'

def get_entry(name)
  parse_cluster_txt.select { |e| e['runlist'].include? name }.first
end

def head_nodes
  parse_cluster_txt.select { |e| e['runlist'].include? 'Head' }
end

def worker_nodes
  parse_cluster_txt.select { |e| e['runlist'].include? 'Worker' }
end

def virtualbox_vm?(entry)
  /^08:00:27/.match(entry['mac_address'])
end

def parse_cluster_txt
  fields =
    %w(hostname mac_address ip_address ilo_address cobbler_profile
       dns_domain runlist)
  # This is really gross because Ruby 1.9 lacks Array#to_h.
  File.readlines(File.join(repo_dir, 'cluster.txt'))
    .map { |line| Hash[*fields.zip(line.split(' ')).flatten(1)] }
end

def repo_dir
  File.dirname(__FILE__)
end

# check the status of the Mixlib::Shellout c
# print on_fail_msg if it fails, along with stdout and stderr
# throw an excpetion if dofail=true
# print on_success_msg if the command c succeeded
def check_status(c, on_fail_msg, on_success_msg, dofail = false)
  if !c.status.success?
    fail_msg = on_fail_msg + ' ' + c.stdout + '\n' + c.stderr
    if dofail
      fail fail_msg
    else
      puts fail_msg
    end
  else
    puts on_success_msg
  end
end

def stop_zabbix_agent(chef_env, host)
  c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, host['ip_address'],
                           'service zabbix-agent stop', 'sudo')
  c.run_command
  check_status(c, 'Could not stop zabbix agent on ' + host['ip_address'],
               'Stopped zabbix agent on ' + host['ip_address'])
end

def stop_zabbix_server(chef_env, host)
  c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, host['ip_address'],
                           'service zabbix-server stop', 'sudo')
  c.run_command
  check_status(c, 'Could not stop zabbix server on ' + host['ip_address'],
               'Stopped zabbix server on ' + host['ip_address'])
  confirm_service_down(chef_env, host, 'zabbix-server')
end

def stop_zabbix_agent_and_server(chef_env)
  head_nodes.each do |host|
    puts host['ip_address']
    stop_zabbix_agent(chef_env, host)
    stop_zabbix_server(chef_env, host)
  end
end

def uninstall_zabbix_api_gem(chef_env)
  head_nodes.each do |host|
    puts host['ip_address']
    c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, host['ip_address'],
                             '/opt/chef/embedded/bin/gem uninstall zabbixapi',
                             'sudo')
    c.run_command
    check_status(c,
                 'Could not uninstall zabbix api gem on' + host['ip_address'],
                 'Uninstalled zabbix api gem on ' + host['ip_address'])
  end
end

# rubocop:disable all
def find_chef_env
  o = Ohai::System.new
  o.all_plugins

  env_command =
    Mixlib::ShellOut.new('sudo', 'knife',
                         'node', 'show',
                         o[:fqdn] || o[:ip_address], '-E',
                         '-f', 'json')

  env_command.run_command

  unless env_command.status.success?
    fail 'Could not retrieve Chef environment!\n' +
      env_command.stdout + '\n' +
      env_command.stderr
  end

  JSON.parse(env_command.stdout)['chef_environment']
end

def drop_zabbix_database(chef_env, vm_entry, password)
  unless zabbix_table?(chef_env, vm_entry, password)
    return nil
  end
  mysqlcmd = 'mysql -uroot -p' + password + ' -e \'drop database zabbix;\''
  c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, vm_entry['ip_address'],
                           mysqlcmd, 'sudo')
  c.run_command
  check_status(c, 'Could not drop zabbix database ', 'Dropped zabbix database',
               true)
end

def uninstall_zabbix(chef_env)
  commands = [
    'find /etc/ -name *zabbix* -exec rm -f {} \;',
    'find /var/spool/ -name *zabbix* -exec rm -f {} \;',
    'find /var/log/ -name *zabbix* -exec rm -f {} \;',
    'find /usr/local/ -name *zabbix* -exec rm -f {} \;',
    'rm -rf /var/log/zabbix',
    'rm -rf /usr/local/etc/zabbix_agent.conf.d',
    'rm -rf /usr/local/etc/zabbix_server.conf.d',
    'rm -rf /usr/local/etc/zabbix_agentd.conf.d',
    'rm -rf /usr/local/share/zabbix']
  head_nodes.each do |host|
    puts host['ip_address']
    commands.each do |cmd|
      c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, host['ip_address'],
                               cmd, 'sudo')
      c.run_command
    end
  end
end

def zabbix_table?(chef_env, vm_entry, password)
  mysqlcmd = 'mysql -uroot -p' + password + " -e 'show databases;'"
  c = Mixlib::ShellOut.new('./nodessh.sh', chef_env, vm_entry['ip_address'],
                           mysqlcmd, 'sudo')
  c.run_command
  output = c.stdout
  check_status(c, 'Could not retrieve current databases',
               "Retrieved current databases", true)
  puts output
  if output.include? 'zabbix'
    puts 'Need to drop zabbix table'
    return true
  else
    puts 'Zabbix table already gone'
    return false
  end
end

def confirm_service_down(chef_env, vm_entry, service)
  #
  # If it takes more than 2 minutes
  # something is really broken.
  #
  # This will make 30 attempts with a 1 minute sleep between attempts,
  # or timeout after 31 minutes.
  #
  command = 'ps -ef | grep ' + service + ' | grep -v grep'
  Timeout.timeout(120) do
    max = 5
    1.upto(max) do |idx|
      c = Mixlib::ShellOut.new('./nodessh.sh',
                               chef_env, vm_entry['ip_address'], command)
      c.run_command
      if c.exitstatus == 1 && c.stdout == ''
        puts service + ' is down'
        return
      else
        puts 'Waiting for ' + service + " to go down (attempt #{idx}/#{max})"
        sleep 30
      end
    end
  end
  fail 'Could not bring down ' + service
end
# rubocop:enable all

#
# This conditional allows us to use the methods into irb instead of
# invoking the script from a UNIX shell.
#
if __FILE__ == $PROGRAM_NAME

  options = {}
  parser = OptionParser.new do|opts|
    opts.banner = 'Usage: uninstall_zabbix.rb [options]'

    opts.on('-p password', '--password=password',
            'mysql password') do |password|
      options[:mysqlpassword] = password
    end
    opts.on('-h', '--help', 'Displays Help') do
      puts opts
      exit
    end
  end

  parser.parse!

  if options[:mysqlpassword].nil?
    puts parser
    exit(-1)
  end

  vm_entry = get_entry('BCPC-Hadoop-Head-Namenode')

  if vm_entry.nil?
    puts "'#{options[:machine]}' was not found in cluster.txt!"
    exit(-1)
  end

  chef_env = find_chef_env
  stop_zabbix_agent_and_server(chef_env)
  drop_zabbix_database(chef_env, vm_entry, options[:mysqlpassword])
  uninstall_zabbix_api_gem(chef_env)
  uninstall_zabbix(chef_env)

end
