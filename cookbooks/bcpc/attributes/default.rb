###########################################
#
#  General configuration for this cluster
#
###########################################
default['bcpc']['country'] = "US"
default['bcpc']['state'] = "NY"
default['bcpc']['location'] = "New York"
default['bcpc']['organization'] = "Bloomberg"
# Region name for this cluster
default['bcpc']['region_name'] = node.chef_environment
# Domain name that will be used for DNS
default['bcpc']['domain_name'] = "bcpc.example.com"

default['bcpc']['encrypt_data_bag'] = false

# Specify the kernel you wish to install. For default latest LTS kernel use "linux-server"
default['bcpc']['bootstrap']['preseed']['kernel'] = "linux-generic-lts-trusty"
default['bcpc']['bootstrap']['preseed']['add_kernel_opts'] = "console=ttyS0"
default['bcpc']['bootstrap']['preseed']['late_command'] = "true"
default['bcpc']['bootstrap']['admin_users'] = []

#
# The node_number is used to derive Kafka broker IDs, Zookeeper myid
# files, keepalived node priorities, and other values.  It must be
# unique within a cluster.
#
# The node number is generated from the integer value of the
# management interface mac_address, modulo Java's Integer.MAX_VALUE.
#
# On the provisioning node and during early bootstrap, we won't have
# any of these values, in which case we just don't set the
# node_number.
#
management_interface = begin
                         interface_name = node[:bcpc][:management][:interface]
                         node[:network][:interfaces][interface_name]
                       rescue
                         nil
                       end

if management_interface
  mac_address = management_interface[:addresses].select{ |addr,hash|
    hash['family'] == 'lladdr'
  }.keys.first

  max_value = (2**31 - 1) # Java Integer.MAX_VALUE
  integer_mac = mac_address.downcase.split(':').join.to_i(base=16)
  node.set['bcpc']['node_number'] = integer_mac % max_value
end  


###########################################
#
#  Host-specific defaults for the cluster
#
###########################################
default['bcpc']['bootstrap']['interface'] = "eth0"
default['bcpc']['bootstrap']['pxe_interface'] = "eth1"
default['bcpc']['bootstrap']['server'] = "10.0.100.3"
default['bcpc']['bootstrap']['dhcp_range'] = "10.0.100.14 10.0.100.250"
default['bcpc']['bootstrap']['dhcp_subnet'] = "10.0.100.0"

###########################################
#
#  Ceph settings for the cluster
#
###########################################
# The 'portion' parameters should add up to ~100 across all pools

###########################################
#
#  Network settings for the cluster
#
###########################################
default['bcpc']['management']['vip'] = "10.17.1.15"
default['bcpc']['management']['netmask'] = "255.255.255.0"
default['bcpc']['management']['cidr'] = "10.17.1.0/24"
default['bcpc']['management']['gateway'] = "10.17.1.1"
default['bcpc']['management']['interface'] = "eth0"

default['bcpc']['metadata']['ip'] = "169.254.169.254"

default['bcpc']['storage']['netmask'] = "255.255.255.0"
default['bcpc']['storage']['cidr'] = "100.100.0.0/24"
default['bcpc']['storage']['gateway'] = "100.100.0.1"
default['bcpc']['storage']['interface'] = "eth1"

default['bcpc']['floating']['vip'] = "192.168.43.15"
default['bcpc']['floating']['netmask'] = "255.255.255.0"
default['bcpc']['floating']['cidr'] = "192.168.43.0/24"
default['bcpc']['floating']['gateway'] = "192.168.43.2"
default['bcpc']['floating']['available_subnet'] = "192.168.43.128/25"
default['bcpc']['floating']['interface'] = "eth2"

default['bcpc']['ntp_servers'] = [ "pool.ntp.org" ]
default['bcpc']['dns_servers'] = [ "8.8.8.8", "8.8.4.4" ]

###########################################
#
#  Repos for things we rely on
#
###########################################
default['bcpc']['repos']['mysql'] = "http://repo.percona.com/apt"
default['bcpc']['repos']['hwraid'] = "http://hwraid.le-vert.net/ubuntu"
default['bcpc']['repos']['ubuntu-tools'] = "http://ppa.launchpad.net/canonical-support/support-tools/ubuntu"
default['bcpc']['ubuntu']['version'] = "precise"

###########################################
#
#  Default names for db's, pools, and users
#
###########################################
default['bcpc']['pdns_dbname'] = "pdns"
default['bcpc']['zabbix_dbname'] = "zabbix"

default['bcpc']['admin_tenant'] = "AdminTenant"
default['bcpc']['admin_role'] = "Admin"
default['bcpc']['member_role'] = "Member"
default['bcpc']['admin_email'] = "admin@localhost.com"

default['bcpc']['zabbix']['user'] = "zabbix"
default['bcpc']['zabbix']['group'] = "adm"
default['bcpc']['zabbix']['server_port'] = 10051
default['bcpc']['zabbix']['web_port'] = 7777
default['bcpc']['zabbix']['scripts']['sender'] = "/usr/local/bin/run_zabbix_sender.sh"
default['bcpc']['zabbix']['scripts']['mail'] = "/usr/local/bin/zbx_mail.sh"
default['bcpc']['zabbix']['scripts']['query_graphite'] = "/usr/local/bin/query_graphite.py"
# Interval (in seconds) during which we expect chef-client to have run at least once
default['bcpc']['zabbix']['chef_client_check_interval'] = (node['chef_client']['interval'].to_i + node['chef_client']['splay'].to_i) * 2

default['bcpc']['keepalived']['config_template'] = "keepalived.conf_openstack"


#################################################
#  attributes for chef vault download and install
#################################################
default['bcpc']['chefvault']['filename'] = "chef-vault-2.2.4.gem"
default['bcpc']['chefvault']['checksum'] = "8d89c96554f614ec2a80ef20e98b0574c355a6ea119a30bd49aa9cfdcde15b4a"
# gems package pathname
default['bcpc']['bin_dir']['gems'] = '/home/vagrant/chef-bcpc/bins/gems'
# rubygems download website URL
default['bcpc']['gem_source'] = 'https://rubygems.org/downloads'
