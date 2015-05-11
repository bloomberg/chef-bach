###########################################
#
#  General configuration for this cluster
#
###########################################
default['bcpc']['country'] = "US"
default['bcpc']['state'] = "NY"
default['bcpc']['location'] = "New York"
default['bcpc']['organization'] = "Bloomberg"
# Can be "folsom" or "grizzly"
default['bcpc']['openstack_release'] = "grizzly"
# Can be "updates" or "proposed"
default['bcpc']['openstack_branch'] = "proposed"
# Should be kvm (or qemu if testing in VMs)
default['bcpc']['virt_type'] = "kvm"
# Region name for this cluster
default['bcpc']['region_name'] = node.chef_environment
# Domain name that will be used for DNS
default['bcpc']['domain_name'] = "bcpc.example.com"
# Key if Cobalt+VMS is to be used
default['bcpc']['vms_key'] = nil

default['bcpc']['encrypt_data_bag'] = false

# Specify the kernel you wish to install. For default latest LTS kernel use "linux-server"
default['bcpc']['bootstrap']['preseed']['kernel'] = "linux-generic-lts-trusty"
default['bcpc']['bootstrap']['preseed']['add_kernel_opts'] = "console=ttyS0"
default['bcpc']['bootstrap']['preseed']['late_command'] = "true"
default['bcpc']['bootstrap']['admin_users'] = []

###########################################
#
#  Host-specific defaults for the cluster
#
###########################################
default['bcpc']['bootstrap']['interface'] = "eth0"
default['bcpc']['bootstrap']['pxe_interface'] = "eth1"
default['bcpc']['bootstrap']['server'] = "10.0.100.3"
default['bcpc']['bootstrap']['vip'] = node['bcpc']['bootstrap']['server']
default['bcpc']['bootstrap']['dhcp_range'] = "10.0.100.14 10.0.100.250"
default['bcpc']['bootstrap']['dhcp_subnet'] = "10.0.100.0"

###########################################
#
#  Ceph settings for the cluster
#
###########################################
default['bcpc']['ceph']['pgs_per_node'] = 1024
default['bcpc']['ceph']['hdd_disks'] = [ "sdb", "sdc" ]
default['bcpc']['ceph']['ssd_disks'] = [ "sdd", "sde" ]
default['bcpc']['ceph']['enabled_pools'] = [ "ssd", "hdd" ]
# The 'portion' parameters should add up to ~100 across all pools
default['bcpc']['ceph']['rgw']['replicas'] = 3
default['bcpc']['ceph']['rgw']['portion'] = 33
default['bcpc']['ceph']['rgw']['type'] = 'hdd'
default['bcpc']['ceph']['images']['replicas'] = 3
default['bcpc']['ceph']['images']['portion'] = 33
default['bcpc']['ceph']['images']['type'] = 'ssd'
default['bcpc']['ceph']['images']['name'] = "images"
default['bcpc']['ceph']['volumes']['replicas'] = 3
default['bcpc']['ceph']['volumes']['portion'] = 33
default['bcpc']['ceph']['volumes']['name'] = "volumes"
default['bcpc']['ceph']['vms_disk']['replicas'] = 3
default['bcpc']['ceph']['vms_disk']['portion'] = 10
default['bcpc']['ceph']['vms_disk']['type'] = 'ssd'
default['bcpc']['ceph']['vms_disk']['name'] = "vmsdisk"
default['bcpc']['ceph']['vms_mem']['replicas'] = 3
default['bcpc']['ceph']['vms_mem']['portion'] = 10
default['bcpc']['ceph']['vms_mem']['type'] = 'ssd'
default['bcpc']['ceph']['vms_mem']['name'] = "vmsmem"

###########################################
#
#  Network settings for the cluster
#
###########################################
default['bcpc']['management']['vip'] = "1.2.3.5"
default['bcpc']['management']['ip'] = "1.2.3.4"

default['bcpc']['metadata']['ip'] = "169.254.169.254"

default['bcpc']['ntp_servers'] = [ "pool.ntp.org" ]
default['bcpc']['dns_servers'] = [ "8.8.8.8", "8.8.4.4" ]

###########################################
#
#  Repos for things we rely on
#
###########################################
default['bcpc']['repos']['ceph'] = "http://www.ceph.com/debian-dumpling"
default['bcpc']['repos']['ceph-extras'] = "http://www.ceph.com/packages/ceph-extras/debian"
default['bcpc']['repos']['ceph-el6-x86_64'] = "http://ceph.com/rpm-dumpling/el6/x86_64"
default['bcpc']['repos']['ceph-el6-noarch'] = "http://ceph.com/rpm-dumpling/el6/noarch"
default['bcpc']['repos']['rabbitmq'] = "http://www.rabbitmq.com/debian"
default['bcpc']['repos']['mysql'] = "http://repo.percona.com/apt"
default['bcpc']['repos']['openstack'] = "http://ubuntu-cloud.archive.canonical.com/ubuntu"
default['bcpc']['repos']['hwraid'] = "http://hwraid.le-vert.net/ubuntu"
default['bcpc']['repos']['ceph-apache'] = "http://gitbuilder.ceph.com/apache2-deb-precise-x86_64-basic/ref/master"
default['bcpc']['repos']['ceph-fcgi'] = "http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-precise-x86_64-basic/ref/master"
default['bcpc']['repos']['gridcentric'] = "http://downloads.gridcentric.com/packages/%s/%s/ubuntu"
default['bcpc']['repos']['ubuntu-tools'] = "http://ppa.launchpad.net/canonical-support/support-tools/ubuntu"
default['bcpc']['ubuntu']['version'] = "precise"
default["bcpc"]["repos"]["hortonworks"] = 'http://public-repo-1.hortonworks.com/HDP/ubuntu12/2.x/updates/2.3.4.0'
default["bcpc"]["repos"]["hdp_utils"] = 'http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.20/repos/ubuntu12'

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
default['bcpc']['pdns_dbname'] = "pdns"
default['bcpc']['zabbix_dbname'] = "zabbix"

default['bcpc']['admin_tenant'] = "AdminTenant"
default['bcpc']['admin_role'] = "Admin"
default['bcpc']['member_role'] = "Member"
default['bcpc']['admin_email'] = "admin@localhost.com"
default['bcpc']['keepalived']['config_template'] = "keepalived.conf_openstack"

default[:bcpc][:ports][:apache][:radosgw] = 8080
default[:bcpc][:ports][:apache][:radosgw_https] = 8443
default[:bcpc][:ports][:haproxy][:radosgw] = 80
default[:bcpc][:ports][:haproxy][:radosgw_https] = 443

# Memory where InnoDB caches table and index data (in MB). Default is 128M.
default['bcpc']['mysql']['innodb_buffer_pool_size'] = [(node[:memory][:total].to_i / 1024 * 0.02).floor, 128].max

#################################################
#  attributes for chef vault download and install
#################################################
default['bcpc']['chefvault']['filename'] = "chef-vault-2.2.4.gem"
default['bcpc']['chefvault']['checksum'] = "8d89c96554f614ec2a80ef20e98b0574c355a6ea119a30bd49aa9cfdcde15b4a"
# bcpc binary server pathnames
default['bcpc']['bin_dir']['path'] = '/home/vagrant/chef-bcpc/bins/'
default['bcpc']['bin_dir']['gems'] = "#{node['bcpc']['bin_dir']['path']}/gems"
# rubygems download website URL
default['bcpc']['gem_source'] = 'https://rubygems.org/downloads'

# mysql connector attributes
default['bcpc']['mysql']['connector']['version'] = '5.1.37'
default['bcpc']['mysql']['connector']['tarball_md5sum'] = '9ef584d3328735db51bd5dde3f602c22'
default['bcpc']['mysql']['connector']['url'] = "http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-#{node['bcpc']['mysql']['connector']['version']}.tar.gz"
default['bcpc']['mysql']['connector']['package']['short_name'] = 'mysql-connector-java'
default['bcpc']['mysql']['connector']['package']['name'] = "#{node['bcpc']['mysql']['connector']['package']['short_name']}_#{node['bcpc']['mysql']['connector']['version']}_all.deb"
