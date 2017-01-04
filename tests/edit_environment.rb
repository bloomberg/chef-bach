#!/usr/bin/env ruby
#
# This script injects proxy, DNS, and NTP configurations into the
# "Test-Laptop" environment for VM cluster builds.
#
# We attempt to auto-detect these values.  To override DNS, NTP, or
# proxy servers, export the appropriate environment variable before
# calling ./tests/automated_install.sh.
#
# Proxy:
#   http_proxy
#
# DNS server:
#   BACH_DNS_SERVER
#
# NTP server:
#   BACH_NTP_SERVER
#

require 'json'
require 'uri'

def get_name_server
  ns = File.readlines('/etc/resolv.conf').select do |ll|
    ll.include?('nameserver')
  end.first.chomp.gsub(/^\s*nameserver\s*/,'')

  if ns == '127.0.0.1'
    # Find the newest DHCP client lease file
    latest_lease = Dir.glob('/var/lib/dhcp/dhclient*.lease*').sort do |a, b|
      File.mtime(a) <=> File.mtime(b)
    end.last

    # Look for a DNS option in the lease
    dns_option = File.readlines(latest_lease).select do |ll|
      ll.include?('option domain-name-servers')
    end.first

    # If we found a DNS option, extract a name server.
    if dns_option
      dns_option.chomp.gsub(/^\s*option domain-name-servers\s*([^,]*),.*/,'\1')
    else
      raise 'No DNS server provided, and none found in local DHCP leases'
    end
  else
    ns
  end
end

name_server = ENV['BACH_DNS_SERVER'] || get_name_server
ntp_server = ENV['BACH_NTP_SERVER'] || name_server
proxy_uri = if ENV['http_proxy']
              URI.parse(ENV['http_proxy'])
            else
              nil
            end

#
# This file is in the 'tests' subdir, so __FILE__/.. is our repo dir.
#
repo_dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

#
# Some versions of VBox were fond of running a DHCP server by default
# on every virtual network.  Remove it, if present.
#
system('vboxmanage dhcpserver remove ' +
       '--netname HostInterfaceNetworking-vboxnet0')

#
# Remove any prior local changes made by shell scripts
#
Dir.chdir(repo_dir) {
  system('git checkout -- Vagrantfile')
  system('rm -f Berksfile.lock')
}

#
# Edit a correct NTP server into the environment.  If the stub
# environment hasn't already been copied into place, we'll have to do
# that first.
#
cluster_dir = File.join(repo_dir, '..', 'cluster')

unless File.directory?(cluster_dir)
  Dir.chdir(repo_dir) {
    system('cp -Rv stub-environment ../cluster')
  }
end

environment_path =
  File.expand_path(File.join(cluster_dir, 'environments', 'Test-Laptop.json'))

environment_data = JSON.parse(File.read(environment_path))

environment_data['override_attributes'].tap do |attrs|
  attrs['bcpc']['ntp_servers'] = [ntp_server]
  attrs['bcpc']['dns_servers'] = [name_server]

  if proxy_uri
    attrs['bcpc']['bootstrap']['proxy'] = proxy_uri.to_s
  end
end

File.write(environment_path, JSON.pretty_generate(environment_data))

if proxy_uri
  puts 'Set $.override_attributes.bcpc.bootstrap.proxy to ' +
    proxy_uri.to_s + ' in ' + environment_path
end

puts 'Set $.override_attributes.bcpc.dns_servers to ' + [name_server].inspect +
  ' in ' + environment_path

puts 'Set $.override_attributes.bcpc.ntp_servers to ' + [ntp_server].inspect +
  ' in ' + environment_path
