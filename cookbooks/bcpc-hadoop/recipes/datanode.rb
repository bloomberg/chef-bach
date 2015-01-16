include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::hive_config'

node.default['bcpc']['hadoop']['copylog']['datanode'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-datanode-#{node.hostname}.log",
    'docopy' => true
}

%w{hadoop-yarn-nodemanager
   hadoop-hdfs-datanode
   hadoop-mapreduce
   hadoop-client
   sqoop
   lzop
   hadoop-lzo}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

template "/etc/init.d/hadoop-hdfs-datanode" do
  source "hdp_hadoop-hdfs-datanode-initd.erb"
  mode 0655
end

template "/etc/init.d/hadoop-yarn-nodemanager" do
  source "hdp_hadoop-yarn-nodemanager-initd.erb"
  mode 0655
end

link "/usr/lib/hadoop/lib/native/libgplcompression.la" do
  to "/usr/lib/hadoop/lib/native/Linux-amd64-64/libgplcompression.la"
end

link "/usr/lib/hadoop/lib/native/libgplcompression.a" do
  to "/usr/lib/hadoop/lib/native/Linux-amd64-64/libgplcompression.a"
end

link "/usr/lib/hadoop/lib/native/libgplcompression.so.0.0.0" do
  to "/usr/lib/hadoop/lib/native/Linux-amd64-64/libgplcompression.so.0.0.0"
end

# Install YARN Bits
template "/etc/hadoop/conf/container-executor.cfg" do
  source "hdp_container-executor.cfg.erb"
  owner "root"
  group "yarn"
  mode "0400"
  variables(:mounts => node[:bcpc][:hadoop][:mounts])
  action :create
  notifies :run, "bash[verify-container-executor]", :immediate
end

bash "verify-container-executor" do
  code "/usr/lib/hadoop-yarn/bin/container-executor --checksetup"
  group "yarn"
  action :nothing
  only_if { File.exists?("/usr/lib/hadoop-yarn/bin/container-executor") }
end

# Install Sqoop Bits
template "/etc/sqoop/conf/sqoop-env.sh" do
  source "sq_sqoop-env.sh.erb"
  mode "0444"
  action :create
end

# Install Hive Bits
# workaround for hcatalog dpkg not creating the hcat user it requires
user "hcat" do 
  username "hcat"
  system true
  shell "/bin/bash"
  home "/usr/lib/hcatalog"
  supports :manage_home => false
end

#%w{hive hcatalog libmysql-java}.each do |pkg|
#  package pkg do
#    action :upgrade
#  end
#end

package 'hive-hcatalog' do
  action :upgrade
end

#link "/usr/lib/hive/lib/mysql.jar" do
#  to "/usr/share/java/mysql.jar"
#end

link "/usr/hdp/current/hive-metastore/lib/mysql-connector-java.jar" do
  to "/usr/share/java/mysql-connector-java.jar"
end

link "/usr/hdp/current/hive-server2/lib/mysql-connector-java.jar" do
  to "/usr/share/java/mysql-connector-java.jar"
end

# Setup datanode and nodemanager bits
if node[:bcpc][:hadoop][:mounts].length <= node[:bcpc][:hadoop][:hdfs][:failed_volumes_tolerated]
  Chef::Application.fatal!("You have fewer #{node[:bcpc][:hadoop][:disks]} than #{node[:bcpc][:hadoop][:hdfs][:failed_volumes_tolerated]}! See comments of HDFS-4442.")
end

# Build nodes for HDFS storage
node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/dfs" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
  end
  directory "/disk/#{i}/dfs/dn" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
  end
end

# Build nodes for YARN log storage
node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/yarn/" do
    owner "yarn"
    group "yarn"
    mode 0755
    action :create
  end
  %w{mapred-local local logs}.each do |d|
    directory "/disk/#{i}/yarn/#{d}" do
      owner "yarn"
      group "hadoop"
      mode 0755
      action :create
    end
  end
end

#
# When there is a need to restart datanode, a lock need to be taken so that the restart is sequenced preventing all DNs being down at the sametime
# If there is a failure in acquiring a lock with in a certian period, the restart is scheduled for the next run on chef-client on the node.
# To determine whether the prev restart failed is the node attribute node[:bcpc][:hadoop][:datanode][:restart_failed] is set to true
# This ruby block is to check whether this node attribute is set to true and if it is set then gets the DN restart process in motion.
#
ruby_block "handle_prev_datanode_restart_failure" do
  block do
    Chef::Log.info "Need to restart DN since it failed during the previous run. Another node's DN restart process failure is a possible reason"
  end
  action :create
  only_if { node[:bcpc][:hadoop][:datanode][:restart_failed] }
end

#
# Since string with all the zookeeper nodes is used multiple times this variable is populated once and reused reducing calls to Chef server
#
zk_hosts = (get_node_attributes(MGMT_IP_ATTR_SRCH_KEYS,"zookeeper_server","bcpc-hadoop").map{|zkhost| "#{zkhost['mgmt_ip']}:#{node[:bcpc][:hadoop][:zookeeper][:port]}"}).join(",")
#
# znode is used as the locking mechnism to control restart of services. The following code is to build the path
# to create the znode before initiating the restart of HDFS datanode service 
#
if (! node[:bcpc][:hadoop][:restart_lock].attribute?(:root) or  node[:bcpc][:hadoop][:restart_lock][:root].nil?)
  lock_znode_path = "/hadoop-hdfs-datanode"
elsif (node[:bcpc][:hadoop][:restart_lock][:root] == "/")
  lock_znode_path = "/hadoop-hdfs-datanode"
else
  lock_znode_path = "#{node[:bcpc][:hadoop][:restart_lock][:root]}/hadoop-hdfs-datanode"
end
#
# All datanode restart situations like changes in config files or restart due to previous failures invokes this ruby_block
# This ruby block tries to acquire a lock and if not able to acquire the lock, sets the restart_failed node attribute to true
#
ruby_block "acquire_lock_to_restart_datanode" do
  block do
    tries = 0
    Chef::Log.info("#{node[:hostname]}: Acquring lock at #{lock_znode_path}")
    while true 
      lock = acquire_restart_lock(lock_znode_path, zk_hosts, node[:fqdn])
      if lock
        break
      else
        tries += 1
        if tries >= node[:bcpc][:hadoop][:restart_lock_acquire][:max_tries]
          Chef::Log.info("Couldn't acquire lock to restart datanode with in the #{node[:bcpc][:hadoop][:restart_lock_acquire][:max_tries] * node[:bcpc][:hadoop][:restart_lock_acquire][:sleep_time]} secs.")
          Chef::Log.info("Node #{get_restart_lock_holder(lock_znode_path, zk_hosts)} may have died during datanode restart.")
          node.set[:bcpc][:hadoop][:datanode][:restart_failed] = true
          node.save
          break
        end
        sleep(node[:bcpc][:hadoop][:restart_lock_acquire][:sleep_time])
      end
    end
  end
  action :nothing
  subscribes :create, "template[/etc/hadoop/conf/hdfs-site.xml]", :immediate
  subscribes :create, "template[/etc/hadoop/conf/hadoop-env.sh]", :immediate
  subscribes :create, "template[/etc/hadoop/conf/topology]", :immediate
  subscribes :create, "ruby_block[handle_prev_datanode_restart_failure]", :immediate
end
#
# If lock to restart datanode is acquired by the node, this ruby_block executes which is primarily used to notify the datanode service to restart
#
ruby_block "coordinate_datanode_restart" do
  block do
    Chef::Log.info("Data node will be restarted in node #{node[:fqdn]}")
  end
  action :create
  only_if { my_restart_lock?(lock_znode_path, zk_hosts, node[:fqdn]) }
end

service "hadoop-hdfs-datanode" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "ruby_block[coordinate_datanode_restart]", :immediate
end

#
# Once the datanode service restart is complete, the following block releases the lock if the node executing is the one which holds the lock 
#
ruby_block "release_datanode_restart_lock" do
  block do
    Chef::Log.info("#{node[:hostname]}: Releasing lock at #{lock_znode_path}")
    lock_rel = rel_restart_lock(lock_znode_path, zk_hosts, node[:fqdn])
    if lock_rel
      node.set[:bcpc][:hadoop][:datanode][:restart_failed] = false
      node.save
    end
  end
  action :create
  only_if { my_restart_lock?(lock_znode_path, zk_hosts, node[:fqdn]) }
end

service "hadoop-yarn-nodemanager" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
end
