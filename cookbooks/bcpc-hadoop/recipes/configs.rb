require 'base64'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

include_recipe 'bcpc-hadoop::default'

# disable IPv6 (e.g. for HADOOP-8568)
case node['platform_family']
when 'debian'
  %w(net.ipv6.conf.all.disable_ipv6
     net.ipv6.conf.default.disable_ipv6
     net.ipv6.conf.lo.disable_ipv6).each do |param|
    sysctl_param param do
      value 1
    end
  end
else
  Chef::Log.warn '============ Unable to disable IPv6 for non-Debian systems'
end

# Populate node attributes for all kind of hosts
set_hosts
node.override['locking_resource']['zookeeper_servers'] = \
  node['bcpc']['hadoop']['zookeeper']['servers'].map do |server|
    [float_host(server['hostname']), node['bcpc']['hadoop']['zookeeper']['port']].join(':')
  end

package 'bigtop-jsvc'

template 'hadoop-detect-javahome' do
  path '/usr/lib/bigtop-utils/bigtop-detect-javahome'
  source 'hdp_bigtop-detect-javahome.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

package 'hdp-select' do
  action :upgrade
end

# Install Java
include_recipe 'java::default'
include_recipe 'java::oracle_jce'

# jvmkill
include_recipe 'bcpc-hadoop::jvmkill'

%w(zookeeper).each do |pkg|
  package hwx_pkg_str(pkg, node['bcpc']['hadoop']['distribution']['release']) do
    action :upgrade
  end
end

# increase max_map_count -- found Java threads will consume these
max_maps = node['memory']['total'].to_i / 16
sysctl_param 'vm.max_map_count' do
  value max_maps
end
