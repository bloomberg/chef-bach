#
# Cookbook Name:: bcpc
# Recipe:: networking
#
# Copyright 2015, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'bcpc::default'
include_recipe 'bcpc::certs_deploy'
include_recipe 'bcpc::ssh'

template '/etc/hosts' do
  source 'hosts.erb'
  mode 00644
  variables(servers: get_all_nodes)
end

service 'cron' do
  action [:enable, :start]
end

# Core networking package
package 'vlan'

# Useful networking tools
%w(
  ethtool
  iperf
  mtr-tiny
  iptraf
  ethstatus
  iftop
  nmap
  ngrep
).each do |p|
  package p do
    action :upgrade
  end
end

# Remove spurious logging failures from this package
package 'powernap' do
  action :remove
end

log 'udev persistent-net.rules file found! Your NICs may have been renamed.' do
  level :warn
  only_if { File.exists?('/etc/udev/rules.d/70-persistent-nic.rules') }
end

#
# Disable NIC renaming on future boots by creating an empty
# persistent-net-generator to override the one in /lib/udev
#
file '/etc/udev/rules.d/75-persistent-net-generator.rules' do
  content "# This file was created by Chef.\n" \
          "# (It is intentionally empty.)\n"
  mode 0444
end

# Remove existing NIC renaming rules.
file '/etc/udev/rules.d/70-persistent-net.rules' do
  action :delete
end

bash 'enable-ip-forwarding' do
  user 'root'
  code(
    <<-EOH
      echo "1" > /proc/sys/net/ipv4/ip_forward
      sed --in-place '/^net.ipv4.ip_forward/d' /etc/sysctl.conf
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    EOH
  )
  not_if "grep -e '^net.ipv4.ip_forward=1' /etc/sysctl.conf"
end

bash 'enable-nonlocal-bind' do
  user 'root'
  code(
    <<-EOH
      echo "1" > /proc/sys/net/ipv4/ip_nonlocal_bind
      sed --in-place '/^net.ipv4.ip_nonlocal_bind/d' /etc/sysctl.conf
      echo 'net.ipv4.ip_nonlocal_bind=1' >> /etc/sysctl.conf
    EOH
  )
  not_if "grep -e '^net.ipv4.ip_nonlocal_bind=1' /etc/sysctl.conf"
end

bash 'set-tcp-keepalive-timeout' do
  user 'root'
  code(
    <<-EOH
      echo "1800" > /proc/sys/net/ipv4/tcp_keepalive_time
      sed --in-place '/^net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf
      echo 'net.ipv4.tcp_keepalive_time=1800' >> /etc/sysctl.conf
    EOH
  )
  not_if "grep -e '^net.ipv4.tcp_keepalive_time=1800' /etc/sysctl.conf"
end

subnet = node[:bcpc][:management][:subnet]

node.run_state['bcpc_networking_modules'] = %w(8021q mlx4_en)

# XXX change subnet to pod or cell!!!
if %w(floating storage management).select do |i|
    node[:bcpc][:networks][subnet][i].attribute?('slaves')
  end.any?

  package 'ifenslave' do
    action :purge
  end

  node.run_state['bcpc_networking_modules'] << 'bonding'
end

node.run_state['bcpc_networking_modules'].each do |module_name|
  execute "enable-#{module_name}-module" do
    command "echo '#{module_name}' >> /etc/modules"
    not_if "grep -e '^#{module_name}' /etc/modules"
  end

  execute "load-#{module_name}-module" do
    command "modprobe #{module_name}"
    not_if "lsmod | grep -e '^#{module_name}'"
  end
end

directory '/etc/network/interfaces.d' do
  owner 'root'
  group 'root'
  mode 00755
  action :create
end

file '/etc/network/interfaces' do
  mode 0444
  content <<-EOM.gsub(/^ {4}/, '')
    #
    # This file was configured by Chef.
    # Local changes will be reverted.
    #
    auto lo
    iface lo inet loopback

    source /etc/network/interfaces.d/*.cfg
  EOM
end

#
# set up the DNS resolvers
# we want the VIP which will be running powerdns to be first on the list
# but the first entry in our master list is also the only one in pdns,
# so make that the last entry to minimize double failures when upstream dies.
#
resolvers = node[:bcpc][:dns_servers].dup

if node[:bcpc][:management][:vip] && get_nodes_for('powerdns').any?
  resolvers.push resolvers.shift
  resolvers.unshift node[:bcpc][:management][:vip]
end

ruby_block 'bcpc-add-resolvers' do
  resolvconf_interface_name =
    node[:bcpc][:networks][subnet][:management][:interface].to_s

  block do
    require 'English'
    IO.popen(['resolvconf', '-a', resolvconf_interface_name],
             'r+') do |resolvconf|
      resolvers.each do |rr|
        resolvconf.puts("nameserver #{rr}")
      end
      resolvconf.puts("search #{node[:bcpc][:domain_name]}")
      resolvconf.close_write
      Chef::Log.debug('Resolvconf output:' + resolvconf.gets.to_s)
    end

    raise 'Failed to add resolvers!' unless $CHILD_STATUS.success?
  end
end

ifaces = %w(management storage floating)
ifaces.each_index do |i|
  iface = ifaces[i]
  device_name = node[:bcpc][:networks][subnet][iface][:interface]

  network_template_variables =
    {
     interface: node[:bcpc][:networks][subnet][iface][:interface],
     ip: node[:bcpc][iface][:ip],
     netmask: node[:bcpc][:networks][subnet][iface][:netmask],
     gateway: node[:bcpc][:networks][subnet][iface][:gateway],
     slaves: node[:bcpc][:networks][subnet][iface]['slaves'] || false,
     dns: resolvers,
     mtu: node[:bcpc][:networks][subnet][iface][:mtu],
     metric: i * 100
    }

  template "/etc/network/interfaces.d/#{device_name}.cfg" do
    source 'network.iface.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables network_template_variables
  end

  if network_template_variables[:slaves]
    template "/usr/local/sbin/pre-up.#{device_name}.sh" do
      source 'network-interface-pre-up.sh.erb'
      owner 'root'
      group 'root'
      mode 0555
      variables network_template_variables
    end
  end
end

execute 'bcpc-interfaces-up' do
  command 'ifup -a'
end

ruby_block 'bcpc-deconfigure-dhcp-interfaces' do
  action :run
  block do
    # Read the DHCP lease files, then pull all the interface names out.
    lease_interface_regex = /\s*interface\s+"(.*?)"\s*;\s*$/

    lease_files = Dir.glob('/var/lib/dhcp/dhclient*.leases')

    lease_interface_lines = lease_files.map do |file_name|
      ::File.readlines(file_name).select do |line|
        line.include?('interface')
      end
    end.flatten

    # This is a list of all interfaces mentioned in DHCP lease files.
    lease_interfaces = lease_interface_lines.map do |line|
      lease_interface_regex.match(line)[1] rescue nil
    end.compact.uniq

    # This is a list of all interfaces we may use in our bond.
    bonded_interfaces = node[:bcpc][:networks][subnet].values.map do |vv|
      vv['slaves']
    end.compact.flatten.uniq

    #
    # Before we begin, verify that we have a new default route
    # installed -- we do not want to deconfigure any interfaces if the
    # new route and new interface are not up!
    #
    require 'mixlib/shellout'
    route_command = Mixlib::ShellOut.new('ip', 'route')
    route_command.run_command
    route_command.error!

    default_routes = route_command.stdout.lines.select do |line|
      line.start_with?('default')
    end

    #
    # If the list of DHCP-configured interfaces and bond slaves
    # overlaps, or if we have only a single NIC, warn the hapless
    # reader of the log.  (If anything goes wrong, we will stop
    # talking to the user!)
    #
    if bonded_interfaces.none?
      Chef::Log.info('This host is not using a bonded configuration, ' \
                     'so interfaces will not be flushed and restarted. ' \
                     'If something goes wrong, you may not notice until ' \
                     'reboot!')
    elsif (bonded_interfaces & lease_interfaces).any?
      Chef::Log.warn('DANGER: since the boot/DHCP interface is a member of ' \
                     'the LACP bond, we may lose network connectivity ' \
                     'while trying to configure the bond!')
    else
      # If they do NOT overlap, we should have no fewer than two routes.
      if default_routes.length < 2
        raise 'Cannot deconfigure DHCP interfaces (' +
          (lease_interfaces.join(' ') rescue '') + '), ' \
          'fewer than 2 default routes are configured!'
      end
    end

    #
    # Look at the list of interfaces for which a default route is
    # bound, omitting any that are slated to be deconfigured.
    #
    # Unless that list is non-zero, and at least one of them is up, abort!
    #
    route_interface_regex = /^default.*dev\s+(.*?)\s/

    route_interfaces = default_routes.map do |route_line|
      route_interface_regex.match(route_line)[1] rescue nil
    end.compact.uniq

    # Remove any soon-to-be-deconfigured interfaces from the list.
    route_interfaces = route_interfaces - lease_interfaces

    up_command = Mixlib::ShellOut.new('ip', 'link', 'show', 'up')
    up_command.run_command
    up_command.error!

    active_route_interfaces = route_interfaces.select do |iface_name|
      up_command.stdout.lines.select do |line|
        /.*?:\s+#{iface_name}/.match(line)
      end.any?
    end

    #
    # If there are no bond slaves, this shouldn't matter, because we
    # won't be deconfiguring anything (no ip addr flush), only killing
    # the dhclient process and installing a static configuration.
    #
    if bonded_interfaces.any? && active_route_interfaces.none?
      raise 'Cannot deconfigure DHCP interfaces, ' \
        'no active interface would be configured with a default route!'
    end

    #
    # Before we begin killing routes, wait a few seconds for the LACP
    # link to settle.
    #
    settle_time = 10
    Chef::Log.debug("Sleeping #{settle_time} seconds before " \
                     'deconfiguring interfaces')
    sleep(settle_time)

    #
    # Kill all dhclient instances.
    #
    Chef::Resource::Execute.new('bcpc-kill-dhclient',
                                 run_context).tap do |r|
      r.command 'pkill -u root dhclient'
      r.run_action :run
    end

    #
    # De-configure each interface manually.
    #
    # It can't be done with ifdown because we no longer have a
    # definition in /etc/network/interfaces for our target interfaces.
    #
    # Commands are executed with generated resources so that each one
    # prints out nicely in the chef-client log.
    #
    deliberately_configured_interfaces =
      node[:bcpc][:networks][subnet].values.map do |nn|
        nn[:interface]
      end.uniq

    deconfigure_targets =
      lease_interfaces - deliberately_configured_interfaces

    deconfigure_targets.each do |interface|
      Chef::Resource::Execute.new("bcpc-deconfigure-#{interface}",
                                  run_context).tap do |r|
        r.command "ip addr flush dev #{interface}; ifup -a"
        r.run_action :run
      end
    end
  end
  only_if 'pgrep dhclient'
end

if node[:bcpc][:networks][subnet][:management][:interface] !=
   node[:bcpc][:networks][subnet][:storage][:interface]
  bash 'routing-storage' do
    user 'root'
    code "echo '2 storage' >> /etc/iproute2/rt_tables"
    not_if "grep -e '^2 storage' /etc/iproute2/rt_tables"
  end
end

#
# Routing scripts for multi-home hosts
#
# These scripts are primarily used in VM clusters.  They must be run
# after deconfiguring DHCP interfaces because otherwise the
# deconfigure block won't find the duplicate default gateway in order
# to identify deconfigurable devices.
#
unique_interfaces =
  node[:bcpc][:networks][subnet].values.map do |nn|
    nn[:interface]
  end.uniq

if unique_interfaces.length > 1
  bash 'routing-management' do
    user 'root'
    code "echo '1 mgmt' >> /etc/iproute2/rt_tables"
    not_if "grep -e '^1 mgmt' /etc/iproute2/rt_tables"
  end

  template '/etc/network/if-up.d/bcpc-routing' do
    mode 00775
    source 'bcpc-routing.erb'
    notifies :run, 'execute[run-routing-script-once]', :immediately
  end

  execute 'run-routing-script-once' do
    action :nothing
    command '/etc/network/if-up.d/bcpc-routing'
  end
end

delete_lines 'disable-noninteractive-pam-logging' do
  path '/etc/pam.d/common-session-noninteractive'
  pattern '^session\s+required\s+pam_unix.so'
end
