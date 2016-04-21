include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::hive_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

node.default['bcpc']['hadoop']['copylog']['datanode'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-datanode-#{node.hostname}.log",
    'docopy' => true
}

hdp_select_pkgs = %w{
  hadoop-yarn-nodemanager
  hadoop-hdfs-datanode
  hadoop-client}

hdp_pkg_strs = (hdp_select_pkgs + %W{
  hadoop-mapreduce
  sqoop
  hadooplzo
  hadooplzo-native}).map{|p| hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release])}

(hdp_pkg_strs + %W{
  #{node['bcpc']['mysql']['connector']['package']['short_name']}
  cgroup-bin}).each do |pkg|
  package pkg do
    action :install
  end
end

(hdp_select_pkgs + ['sqoop-client', 'sqoop-server']).each do |pkg|
  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

user_ulimit "root" do
  filehandle_limit 32769
  process_limit 65536
end

user_ulimit "hdfs" do
  filehandle_limit 32769
  process_limit 65536
end

user_ulimit "mapred" do
  filehandle_limit 32769
  process_limit 65536
end

user_ulimit "yarn" do
  filehandle_limit 32769
  process_limit 65536
end

configure_kerberos 'datanode_kerb' do
  service_name 'datanode'
end

configure_kerberos 'nodemanager_kerb' do
  service_name 'nodemanager'
end

configure_kerberos 'mapred_kerb' do
  service_name 'historyserver'
end
# need to ensure hdfs user is in hadoop and hdfs
# groups. Packages will not add hdfs if it
# is already created at install time (e.g. if
# machine is using LDAP for users).
# Similarly, yarn needs to be in the hadoop
# group to run the LCE and in the mapred group
# for log aggregation

# Create all the resources to add them in resource collection
node[:bcpc][:hadoop][:os][:group].keys.each do |group_name|
  node[:bcpc][:hadoop][:os][:group][group_name][:members].each do|user_name|
    user user_name do
      home "/var/lib/hadoop-#{user_name}"
      shell '/bin/bash'
      system true
      action :create
      not_if { user_exists?(user_name) }
    end
  end

  group group_name do
    append true
    members node[:bcpc][:hadoop][:os][:group][group_name][:members]
    action :nothing
  end
end
  
# Take action on each group resource based on its existence 
ruby_block 'create_or_manage_groups' do
  block do
    node[:bcpc][:hadoop][:os][:group].keys.each do |group_name|
      res = run_context.resource_collection.find("group[#{group_name}]")
      res.run_action(get_group_action(group_name))
    end
  end
end

directory "/var/run/hadoop-hdfs" do
  owner "hdfs"
  group "root"
end

directory "/sys/fs/cgroup/cpu/hadoop-yarn" do
  owner "yarn"
  group "yarn"
  mode 0755
  action :create
end

execute "chown hadoop-yarn cgroup tree to yarn" do
  command "chown -Rf yarn:yarn /sys/fs/cgroup/cpu/hadoop-yarn"
  action :run
end

link "/etc/init.d/hadoop-hdfs-datanode" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-hdfs/etc/init.d/hadoop-hdfs-datanode"
  notifies :run, "bash[kill hdfs-hdfs-datanode]", :immediate
end

bash "kill hdfs-hdfs-datanode" do
  code "pkill -u hdfs -f hdfs-datanode"
  action :nothing
  returns [0, 1]
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
  code "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-yarn/bin/container-executor --checksetup"
  user "yarn"
  group "yarn"
  action :nothing
  only_if { File.exists?("/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-yarn/bin/container-executor") }
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
  not_if { user_exists? "hcat" }
end

package hwx_pkg_str('hive-hcatalog', node[:bcpc][:hadoop][:distribution][:release]) do
  action :install
end

hdp_select('hive-webhcat', node[:bcpc][:hadoop][:distribution][:active_release])

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

link "/etc/init.d/hadoop-yarn-nodemanager" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-yarn/etc/init.d/hadoop-yarn-nodemanager"
  notifies :run, "bash[kill yarn-yarn-nodemanager]", :immediate
end

bash "kill yarn-yarn-nodemanager" do
  code "pkill -u yarn -f yarn-nodemanager"
  action :nothing
  returns [0, 1]
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
zk_hosts = (get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"zookeeper_server","bcpc-hadoop").map{|zkhost| "#{float_host(zkhost['hostname'])}:#{node[:bcpc][:hadoop][:zookeeper][:port]}"}).join(",")
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
  subscribes :create, "link[/etc/init.d/hadoop-hdfs-datanode]", :delayed
  subscribes :create, "template[/etc/hadoop/conf/hdfs-site.xml]", :immediate
  subscribes :create, "template[/etc/hadoop/conf/hadoop-metrics2.properties]", :immediate
  subscribes :create, "template[/etc/hadoop/conf/hadoop-env.sh]", :immediate
  subscribes :create, "template[/etc/hadoop/conf/topology]", :immediate
  subscribes :create, "user_ulimit[hdfs]", :immediate
  subscribes :create, "user_ulimit[root]", :immediate
  subscribes :create, "bash[hdp-select hadoop-hdfs-datanode]", :immediate
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
  subscribes :restart, "link[/etc/init.d/hadoop-yarn-nodemanager]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
  subscribes :restart, "bash[hdp-select hadoop-yarn-nodemanager]", :delayed
  subscribes :restart, "user_ulimit[yarn]", :delayed
end
