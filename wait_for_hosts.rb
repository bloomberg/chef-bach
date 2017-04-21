#!/usr/bin/env ruby

require 'date'
require 'mixlib/shellout'
require 'pp'
require 'pry'
require 'socket'

require_relative 'lib/cluster_data'
require_relative 'lib/chef_node'
include BACH::ClusterData
include BACH::ClusterData::ChefNode

def raw_apache_log
  cc = Mixlib::ShellOut.new('sudo cat /var/log/apache2/access.log')
  cc.run_command
  cc.error!
  cc.stdout
end

def parsed_apache_log
  @apache_log_regex ||=
    Regexp.new(/
              ^(\S+)\s           # hostname
              (\S+)\s            # identd (always a bare hyphen)
              (\S+)\s            # http 401 user (usually a bare hyphen)
              \[([^\]]+)\]\s     # timestamp
              "([A-Z]+[^"]*)"\s  # request
              (\d+)\s            # response code
              (\d+)\s            # response size
              "([^"]*)"\s        # referrer
              "([^"]*)"$         # user agent
              /x)

  match_data = raw_apache_log.split("\n").map do |line|
    line.match(@apache_log_regex)
  end.compact

  match_data.map do |md|
    {
     hostname: md[1],
     identd: md[2],
     user: md[3],
     timestamp: DateTime.strptime(md[4], '%d/%b/%Y:%H:%M:%S %z'),
     request: md[5],
     response_code: md[6],
     response_size: md[7],
     referrer: md[8],
     user_agent: md[9]
    }
  end
end

#
# booted_hosts - Tells us where is a host in the boot sequence
# Depends On: parsed_apache_log() 
# Returns:
#  - A hash of:
#    hosts: a hash of hostnames to bootstate
#    messages: an array of match strings
#
def booted_hosts
  # Example log entries which are parsed
  # 10.0.100.11 - - [29/Mar/2017:04:04:28 +0000] "GET /cblr/svc/op/gpxe/system/bcpc-vm1 HTTP/1.1" 200 753 "-" "iPXE/1.0.0+"
  # 10.0.100.11 - - [29/Mar/2017:04:04:28 +0000] "GET /cobbler/images/ubuntu-14.04-mini-x86_64/linux HTTP/1.1" 200 6939425 "-" "iPXE/1.0.0+"
  # 10.0.100.12 - - [29/Mar/2017:04:04:28 +0000] "GET /cblr/svc/op/gpxe/system/bcpc-vm2 HTTP/1.1" 200 753 "-" "iPXE/1.0.0+"
  # 10.0.100.12 - - [29/Mar/2017:04:04:29 +0000] "GET /cobbler/images/ubuntu-14.04-mini-x86_64/linux HTTP/1.1" 200 6939425 "-" "iPXE/1.0.0+"
  # 10.0.100.13 - - [29/Mar/2017:04:04:29 +0000] "GET /cblr/svc/op/gpxe/system/bcpc-vm3 HTTP/1.1" 200 753 "-" "iPXE/1.0.0+"
  # 10.0.100.13 - - [29/Mar/2017:04:04:29 +0000] "GET /cobbler/images/ubuntu-14.04-mini-x86_64/linux HTTP/1.1" 200 6939425 "-" "iPXE/1.0.0+"
  # 10.0.100.11 - - [29/Mar/2017:04:04:28 +0000] "GET /cobbler/images/ubuntu-14.04-mini-x86_64/initrd.gz HTTP/1.1" 200 41147799 "-" "iPXE/1.0.0+"
  # 10.0.100.12 - - [29/Mar/2017:04:04:29 +0000] "GET /cobbler/images/ubuntu-14.04-mini-x86_64/initrd.gz HTTP/1.1" 200 41147799 "-" "iPXE/1.0.0+"
  # 10.0.100.13 - - [29/Mar/2017:04:04:30 +0000] "GET /cobbler/images/ubuntu-14.04-mini-x86_64/initrd.gz HTTP/1.1" 200 41147799 "-" "iPXE/1.0.0+"
  gpxe_url = Regexp.new('/cblr/svc/op/gpxe/system/')
  ubuntu_url = Regexp.new('/cobbler/images/ubuntu-.*-x86_64/linux')
  initrd_url = Regexp.new('/cobbler/images/ubuntu-.*-x86_64/initrd.gz')
  # array should be sorted from first URL to last URL in boot process
  match_strings = [gpxe_url, ubuntu_url, initrd_url]

  # create a hash of hostnames to bootstate from match_strings array
  boot_log_entries = {}
  parsed_apache_log.each do |entry|
    match = match_strings.select { |x| x.match(entry[:request]) }.last
    state = match_strings.index(match)
    boot_log_entries[entry[:hostname]] = \
      [boot_log_entries.fetch(entry[:hostname], -1), state].max if state
  end

  {hosts: boot_log_entries, messages: match_strings}
end

def installed_hosts
  cobbler_nopxe_log_entries = parsed_apache_log.select do |entry|
    entry[:request].include?('/cblr/svc/op/nopxe/system/')
  end
  @request_regex ||=
    Regexp.new('/cblr/svc/op/nopxe/system/(.*?)\s')

  cobbler_nopxe_log_entries.map do |entry|
    md = @request_regex.match(entry[:request])
    md.nil? ? nil : md[1]
  end
end

#
# Argument:
#  host: a hostname or IP address
#
# Returns:
#  - true if connection successful and SSH banner found
#  - false in all other cases
#
def look_for_ssh_banner(host)
  begin
    Timeout.timeout(1) do
      conn = TCPSocket.new(host, 22)
      banner = conn.gets
      conn.close
      banner.include?('OpenSSH') && banner.include?('Ubuntu')
    end
  rescue
    false
  end
end

#
# This method attempts to contact hosts that have nopxe entries in the
# apache log on the SSH port.
#
# IP addresses for each hostname are looked up via cluster.txt.
#
# Argument:
#   target_hosts: a list of hostnames to contact
#
# Returns:
#   - a list of reachable hosts
#
def listening_hosts(target_hosts=installed_hosts)
  host_entries = parse_cluster_txt(cluster_txt).select do |entry|
    target_hosts.include?(entry[:hostname]) ||
    target_hosts.include?(entry[:fqdn])
  end

  host_entries.select do |entry|
    look_for_ssh_banner(entry[:ip_address])
  end.map do |entry|
    entry[:hostname]
  end
end

minutes = 120
(1..minutes).to_a.each do |i|
  puts "Searching for installed hosts, attempt #{i}/#{minutes}\n"

  target_hosts = ARGV.compact.uniq.sort
  all_installed = installed_hosts.sort & target_hosts
  contacted_hosts = listening_hosts(all_installed).sort & target_hosts
  missing_hosts = (target_hosts - contacted_hosts).sort

  booted_hosts_string = booted_hosts[:hosts].map do |host, state|
    "#{host}: stage-#{state}"
  end.join("\n\t\t")
  puts "\tBooted hosts from apache log " \
    "(#{booted_hosts[:hosts].count}/#{target_hosts.count}):\n" \
    "\t\t#{booted_hosts_string}\n\n"

  puts "\tCompleted installations from apache log " \
    "(#{all_installed.count}/#{target_hosts.count}):\n" \
    "\t\t#{all_installed.join(', ')}\n\n"

  puts "\tInstalled hosts that are listening for SSH on port 22 " \
    "(#{contacted_hosts.count}/#{target_hosts.count}):\n" \
    "\t\t#{contacted_hosts.join(', ')}\n\n"

  puts "\tHosts still missing " \
    "(#{missing_hosts.count}/#{target_hosts.count}):\n" \
    "\t\t#{missing_hosts.any? ? missing_hosts.join(', ') : '(none)' }"

  if missing_hosts.none?
    puts "Found all hosts (#{contacted_hosts.count}/#{target_hosts.count}), " \
      'exiting successfully.'
    exit 0
  else
    puts "\n"
    sleep 60
  end
end

puts "Still missing hosts after waiting for #{minutes} minutes!"
exit 1
