###########################################
#
#  General configuration for this cluster
#
###########################################
default['bcpc']['country'] = 'US'
default['bcpc']['state'] = 'NY'
default['bcpc']['location'] = 'New York'
default['bcpc']['organization'] = 'Bloomberg'

# Should be kvm (or qemu if testing in VMs)
default['bcpc']['virt_type'] = 'kvm'

# Region name for this cluster
default['bcpc']['region_name'] = node.chef_environment

# Domain name that will be used for DNS
default['bcpc']['domain_name'] = 'bcpc.example.com'

# Key if Cobalt+VMS is to be used
default['bcpc']['vms_key'] = nil
default['bcpc']['encrypt_data_bag'] = false

default['bcpc']['bootstrap']['preseed'].tap do |preseed|
  # Specify the kernel you wish to install.
  # For default, (latest LTS kernel) use "linux-server"
  preseed['kernel'] = 'linux-generic-lts-xenial'
  preseed['add_kernel_opts'] = 'console=ttyS0'
  preseed['late_command'] = 'true'
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
    fail 'Could not find MAC addresses for ' +
      'node[:network][:default_interface] ' +
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
default['bcpc']['management']['ip'] = '1.2.3.4'

default['bcpc']['metadata']['ip'] = '169.254.169.254'

default['bcpc']['ntp_servers'] = ['pool.ntp.org']
default['bcpc']['dns_servers'] = ['8.8.8.8', '8.8.4.4']

###########################################
#
#  Repos for things we rely on
#
###########################################
default['bcpc']['ubuntu']['version'] = 'precise'

default['bcpc']['repos'].tap do |repos|
  repos['rabbitmq'] = 'http://www.rabbitmq.com/debian'

  repos['mysql'] = 'http://repo.percona.com/apt'

  repos['hwraid'] = 'http://hwraid.le-vert.net/ubuntu'

  repos['gridcentric'] =
    'http://downloads.gridcentric.com/packages/%s/%s/ubuntu'

  repos['ubuntu-tools'] =
    'http://ppa.launchpad.net/canonical-support/support-tools/ubuntu'

  repos['hortonworks'] =
    'http://s3.amazonaws.com/dev.hortonworks.com/HDP/ubuntu12/2.x/BUILDS/2.3.6.2-3'

  repos['hdp_utils'] =
    'http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.20/repos/ubuntu14'

  repos['cobbler26'] =
    'http://download.opensuse.org/repositories/home:/libertas-ict:' \
    "/cobbler26/xUbuntu_#{node[:lsb][:release]}/"
end

###########################################
#
#  Default names for db's, pools, and users
#
###########################################
default['bcpc']['pdns_dbname'] = 'pdns'
default['bcpc']['zabbix_dbname'] = 'zabbix'

default['bcpc']['admin_tenant'] = 'AdminTenant'
default['bcpc']['admin_role'] = 'Admin'
default['bcpc']['member_role'] = 'Member'
default['bcpc']['admin_email'] = 'admin@localhost.com'

default[:bcpc][:ports][:apache][:radosgw] = 8080
default[:bcpc][:ports][:apache][:radosgw_https] = 8443
default[:bcpc][:ports][:haproxy][:radosgw] = 80
default[:bcpc][:ports][:haproxy][:radosgw_https] = 443

# Memory where InnoDB caches table and index data (in MB). Default is 128M.
default['bcpc']['mysql']['innodb_buffer_pool_size'] =
  ([(node[:memory][:total].to_i / 1024 * 0.02).floor, 128].max)

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

# rubygems download website URL
default['bcpc']['gem_source'] = 'https://rubygems.org/downloads'

# mysql connector attributes
default['bcpc']['mysql']['connector'].tap do |connector|
  connector['version'] = '5.1.37'

  connector['tarball_md5sum'] = '9ef584d3328735db51bd5dde3f602c22'

  connector['url'] =
    'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-' +
    node['bcpc']['mysql']['connector']['version'] + '.tar.gz'

  connector['package']['short_name'] = 'mysql-connector-java'

  connector['package']['name'] =
    node['bcpc']['mysql']['connector']['package']['short_name'] + '_' +
    node['bcpc']['mysql']['connector']['version'] + '_all.deb'
end
