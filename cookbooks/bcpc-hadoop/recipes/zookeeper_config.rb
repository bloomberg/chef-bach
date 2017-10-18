#
# Set up zookeeper configs
#

#
# The ZK packages are required because post-install scripts will
# create the ZK user accounts, if absent.
#
include_recipe 'bcpc-hadoop::zookeeper_packages'

conf_dir = node['bcpc']['hadoop']['zookeeper']['conf_dir']

directory "#{conf_dir}.#{node.chef_environment}" do
  owner node['bcpc']['hadoop']['zookeeper']['owner']
  group node['bcpc']['hadoop']['zookeeper']['group']
  mode 00755
  action :create
  recursive true
end

bash 'update-zookeeper-conf-alternatives' do
  code 'update-alternatives ' \
    "--install #{conf_dir} " \
    "zookeeper-conf #{conf_dir}.#{node.chef_environment} 50; " \
    "update-alternatives " \
    "--set zookeeper-conf #{conf_dir}.#{node.chef_environment}"
  not_if "update-alternatives --query zookeeper-conf | " \
    "grep #{node.chef_environment}"
end

template "#{node['bcpc']['hadoop']['zookeeper']['conf_dir']}/zoo.cfg" do
  source "zk_zoo.cfg.erb"
  mode 0644
  #
  # All role:BCPC-Hadoop-Head or role:BCPC-Kafka-Head-Zookeeper nodes
  # currently run ZK, so this should be a safe value for zk_hosts.
  #
  variables(:zk_hosts => get_head_nodes)
  helpers(BCPC::Utils)
end

%w{log4j.properties configuration.xsl}.each do |tt|
  template "#{node['bcpc']['hadoop']['zookeeper']['conf_dir']}/#{tt}" do
    source "zk_#{tt}.erb"
    mode 0644
  end
end

%w{zookeeper-client.jaas zookeeper-server.jaas}.each do |tt|
  template "/etc/zookeeper/conf/#{tt}" do
    source "zk_#{tt}.erb"
    mode 0644
    only_if { node['bcpc']['hadoop']['kerberos']['enable'] }
  end
end
