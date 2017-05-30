###########################################
#
#  General configuration for this cluster
#
###########################################
default['bcpc']['country'] = 'US'
default['bcpc']['state'] = 'NY'
default['bcpc']['location'] = 'New York'
default['bcpc']['organization'] = 'Bloomberg'

# Region name for this cluster
default['bcpc']['region_name'] = node.chef_environment

# Domain name that will be used for DNS
default['bcpc']['domain_name'] = 'bcpc.example.com'

default['bcpc']['encrypt_data_bag'] = false

# This is where you would set a proxy if one is needed at install time.
default['bcpc']['bootstrap']['proxy'] = nil

default['bcpc']['bootstrap']['preseed'].tap do |preseed|
  preseed['add_kernel_opts'] = 'console=ttyS0'
  preseed['additional_packages'] = %w(openssh-server lldpd)

  # Disable device renaming -- use the kernel's enumeration order.
  preseed['late_command'] =
    'rm /target/etc/udev/rules.d/70-persistent-net.rules; ' \
    'touch /target/etc/udev/rules.d/75-persistent-net-generator.rules'

  #
  # This is an ordered array of preferred disk controller kernel
  # drivers.  The first enumerated disk found from the earliest driver
  # in the list will be chosen by the preseed for use as a root device.
  #
  # If none of the drivers are in use, the first available /dev/sd*
  # device will be used.
  #
  # See select_bach_root_disk.erb for details.
  #
  preseed['preferred_disk_drivers'] = ['ahci']

  #
  # All these lines get concatenated, hence the semicolons and
  # backslashes.
  #
  # Despite the name "preseed," this is run during the partman stage.
  # udevadm and friends are already available in the install
  # environment.
  #
  preseed['early_command'] = <<-EOM.gsub(/^ {4}/, '')
      udevadm trigger; udevadm settle --timeout=30 ; \\
      set -- $(vgs --rows --noheadings | head -n 1); \\
      for vg in "$@"; do \\
        echo Removing volume group $vg \\
          >> /tmp/early_command.out; \\
        lvm vgremove -f "$vg" \\
          >> /tmp/early_command.out; \\
      done; \\
      for d in `ls /dev/sd[a-z]*`; do \\
        echo Removing LVM PVs from $d \\
          >> /tmp/early_command.out 2>&1; \\
        lvm pvremove -f $d \\
          >> /tmp/early_command.out 2>&1; \\
        echo Erasing first blocks on $d \\
          >> /tmp/early_command.out 2>&1; \\
        dd if=/dev/zero of=$d bs=64M count=16 \\
          >> /tmp/early_command.out 2>&1; \\
      done
  EOM
end

default['bcpc']['bootstrap']['admin_users'] = []

#
# The node_number is used to derive Kafka broker IDs, Zookeeper myid
# files, keepalived node priorities, and other values.  It must be
# unique within a cluster.
#
# The node number is generated from the integer value of the
# default interface mac_address, modulo Java's Integer.MAX_VALUE.
#
# For 8-bit node numbers, (e.g. zookeeper, keepalived) there is a
# helper method defined in libraries/node_numbers.rb
#
unless node['bcpc']['node_number']
  interface_name = node[:network][:default_interface]
  default_interface = node[:network][:interfaces][interface_name]

  all_macs = default_interface[:addresses].select do |_addr, hash|
    hash['family'] == 'lladdr'
  end

  unless all_macs.count > 0
    fail 'Could not find MAC addresses for ' \
      'node[:network][:default_interface] ' \
      "(#{node[:network][:default_interface]}) !"
  end

  mac_address = all_macs.keys.sort.first

  max_value = (2**31 - 1) # Java Integer.MAX_VALUE
  integer_mac = mac_address.downcase.split(':').join.to_i(16)
  node.set['bcpc']['node_number'] = integer_mac % max_value
end

###########################################
#
#  Host-specific defaults for the cluster
#
###########################################
default['bcpc']['bootstrap']['interface'] = 'eth0'
default['bcpc']['bootstrap']['pxe_interface'] = 'eth1'
default['bcpc']['bootstrap']['server'] = '10.0.100.3'
default['bcpc']['bootstrap']['vip'] = node['bcpc']['bootstrap']['server']
default['bcpc']['bootstrap']['dhcp_range'] = '10.0.100.14 10.0.100.250'
default['bcpc']['bootstrap']['dhcp_subnet'] = '10.0.100.0'

###########################################
#
#  Network settings for the cluster
#
###########################################
default['bcpc']['management']['vip'] = '1.2.3.5'
default['bcpc']['management']['viphost'] = "#{node.chef_environment.downcase}"\
                                           ".#{node['bcpc']['domain_name']}"
default['bcpc']['management']['ip'] = '1.2.3.4'

default['bcpc']['dns_servers'] = ['8.8.8.8', '8.8.4.4']

###########################################
#
#  Repos for things we rely on
#
###########################################
default['bcpc']['repos_for']['precise'].tap do |precise_repos|
  precise_repos['percona'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'precise'
    repo[:key] = 'percona-release.key'
    repo[:uri] = 'http://repo.percona.com/apt'
  end

  precise_repos['canonical-support-tools'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'precise'
    repo[:key] = 'ubuntu-support-tools.key'
    repo[:uri] =
      'http://ppa.launchpad.net/canonical-support/support-tools/ubuntu'
  end

  precise_repos['hortonworks'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'HDP'
    repo[:key] = 'hortonworks.key'
    repo[:uri] =
      'http://s3.amazonaws.com/dev.hortonworks.com/HDP/ubuntu12/2.x/BUILDS/' \
      '2.3.6.2-3'
  end

  precise_repos['hdp-utils'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'HDP-UTILS'
    repo[:key] = 'hortonworks.key'
    repo[:uri] =
      'http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.20/repos/ubuntu12'
  end

  precise_repos['cobbler26'].tap do |repo|
    repo[:components] = ['/']
    repo[:distribution] = nil
    repo[:uri] =
      'http://download.opensuse.org/repositories/home:/libertas-ict:' \
      '/cobbler26/xUbuntu_12.04'
    #
    # The public apt repository is signed with an expired key, so
    # we're forced to use 'trusted' in order to defeat the signing.
    #
    repo[:trusted] = true
  end

  precise_repos['zabbix'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'precise'
    repo[:key] = 'zabbix-official-repo.key'
    repo[:uri] = 'http://repo.zabbix.com/zabbix/2.4/ubuntu/'
  end
end

default['bcpc']['repos_for']['trusty'].tap do |trusty_repos|
  trusty_repos['percona'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'trusty'
    repo[:key] = 'percona-release.key'
    repo[:uri] = 'http://repo.percona.com/apt'
  end

  trusty_repos['canonical-support-tools'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'trusty'
    repo[:key] = 'ubuntu-support-tools.key'
    repo[:uri] =
      'http://ppa.launchpad.net/canonical-support/support-tools/ubuntu'
  end

  trusty_repos['hortonworks'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'HDP'
    repo[:key] = 'hortonworks.key'
    repo[:uri] =
      'http://s3.amazonaws.com/dev.hortonworks.com/HDP/ubuntu14/2.x/BUILDS/' \
      '2.3.6.2-3'
  end

  trusty_repos['hdp-utils'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'HDP-UTILS'
    repo[:key] = 'hortonworks.key'
    repo[:uri] =
      'http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.20/repos/ubuntu14'
  end

  trusty_repos['cobbler26'].tap do |repo|
    repo[:components] = ['/']
    repo[:distribution] = nil
    repo[:uri] =
      'http://download.opensuse.org/repositories/home:/libertas-ict:' \
      '/cobbler26/xUbuntu_14.04'
    #
    # The public apt repository is signed with an expired key, so
    # we're forced to use 'trusted' in order to defeat the signing.
    #
    repo[:trusted] = true
  end

  trusty_repos['zabbix'].tap do |repo|
    repo[:components] = ['main']
    repo[:distribution] = 'trusty'
    repo[:key] = 'zabbix-official-repo.key'
    repo[:uri] = 'http://repo.zabbix.com/zabbix/2.4/ubuntu/'
  end
end

default[:bcpc][:repos] = node[:bcpc][:repos_for][node[:lsb][:codename]]

###########################################
#
#  Overrides for the 'ubuntu' cookbook.
#
###########################################
default[:ubuntu][:archive_url] =
  'http://mirror.math.princeton.edu/pub/ubuntu'

default[:ubuntu][:security_url] =
  node[:ubuntu][:archive_url]

###########################################
#
#  Default names for db's, pools, and users
#
###########################################
default['bcpc']['pdns_dbname'] = 'pdns'
default['bcpc']['zabbix_dbname'] = 'zabbix'

default['bcpc']['admin_email'] = 'admin@example.com'

#################################################
#  attributes for chef vault download and install
#################################################
default['bcpc']['chefvault']['filename'] =
  'chef-vault-2.2.4.gem'

default['bcpc']['chefvault']['checksum'] =
  '8d89c96554f614ec2a80ef20e98b0574c355a6ea119a30bd49aa9cfdcde15b4a'

# bcpc binary server pathnames
default['bcpc']['bin_dir']['path'] = '/home/vagrant/chef-bcpc/bins/'
default['bcpc']['bin_dir']['gems'] = "#{node['bcpc']['bin_dir']['path']}/gems"
