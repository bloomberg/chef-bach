###########################################
#
#  General configuration for this cluster
#
###########################################
# Can be "folsom" or "grizzly"
default['bcpc']['openstack_release'] = "folsom"
# Can be "updates" or "proposed"
default['bcpc']['openstack_branch'] = "proposed"
# Should be kvm (or qemu if testing in VMs)
default['bcpc']['virt_type'] = "kvm"
# Region name for this cluster
default['bcpc']['region_name'] = node.chef_environment
# Domain name that will be used for DNS
default['bcpc']['domain_name'] = "bcpc.test.com"

###########################################
#
#  Host-specific defaults for the cluster
#
###########################################
default['bcpc']['ceph_disks'] = [ "sdb", "sdc", "sdd", "sde" ]
default['bcpc']['management']['interface'] = "eth0"
default['bcpc']['storage']['interface'] = "eth1"
default['bcpc']['floating']['interface'] = "eth2"
default['bcpc']['fixed']['vlan_interface'] = node[:bcpc][:floating][:interface]

###########################################
#
#  Network settings for the cluster
#
###########################################
default['bcpc']['management']['vip'] = "10.17.1.15"
default['bcpc']['management']['netmask'] = "255.255.255.0"
default['bcpc']['management']['cidr'] = "10.17.1.0/24"
default['bcpc']['management']['gateway'] = "10.17.1.1"

default['bcpc']['storage']['netmask'] = "255.255.255.0"
default['bcpc']['storage']['cidr'] = "100.100.0.0/24"
default['bcpc']['storage']['gateway'] = "100.100.0.1"

default['bcpc']['floating']['netmask'] = "255.255.255.0"
default['bcpc']['floating']['cidr'] = "192.168.43.0/24"
default['bcpc']['floating']['gateway'] = "192.168.43.2"
default['bcpc']['floating']['available_subnet'] = "192.168.43.128/25"

default['bcpc']['fixed']['cidr'] = "1.127.0.0/16"
default['bcpc']['fixed']['vlan_start'] = "1000"
default['bcpc']['fixed']['num_networks'] = "100"
default['bcpc']['fixed']['network_size'] = "256"

default['bcpc']['ntp_servers'] = [ "172.17.64.35", "172.17.65.35" ]
default['bcpc']['dns_servers'] = [ "192.168.43.2", "10.17.1.20" ]

###########################################
#
#  Repos for things we rely on
#
###########################################
default['bcpc']['repos']['ceph'] = "http://www.ceph.com/debian-bobtail/"
default['bcpc']['repos']['mysql'] = "http://repo.percona.com/apt"
default['bcpc']['repos']['openstack'] = "http://ubuntu-cloud.archive.canonical.com/ubuntu"
default['bcpc']['repos']['hwraid'] = "http://hwraid.le-vert.net/ubuntu"

###########################################
#
#  Default names for db's, pools, and users
#
###########################################
default['bcpc']['nova_dbname'] = "nova"
default['bcpc']['cinder_dbname'] = "cinder"
default['bcpc']['glance_dbname'] = "glance"
default['bcpc']['horizon_dbname'] = "horizon"
default['bcpc']['keystone_dbname'] = "keystone"
default['bcpc']['graphite_dbname'] = "graphite"
default['bcpc']['pdns_dbname'] = "pdns"

default['bcpc']['cinder_rbd_pool'] = "volumes"
default['bcpc']['glance_rbd_pool'] = "images"

default['bcpc']['admin_tenant'] = "AdminTenant"
default['bcpc']['admin_role'] = "Admin"
default['bcpc']['member_role'] = "Member"
default['bcpc']['admin_email'] = "admin@localhost.com"

default['bcpc']['beaver']['user'] = "beaver"
default['bcpc']['beaver']['group'] = "adm"
default['bcpc']['logstash']['user'] = "logstash"
default['bcpc']['logstash']['group'] = "adm"
default['bcpc']['kibana']['user'] = "kibana"
default['bcpc']['kibana']['group'] = "adm"

###########################################
#
#  Default AD configuration (if available)
#
###########################################
default['bcpc']['vas']['ou'] = ""
default['bcpc']['vas']['domain'] = ""
