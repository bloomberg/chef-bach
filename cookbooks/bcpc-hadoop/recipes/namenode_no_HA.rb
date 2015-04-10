include_recipe 'dpkg_autostart'
require "base64"

include_recipe 'bcpc-hadoop::hadoop_config'

#
# Updating node attribuetes to copy namenode log files to centralized location (HDFS)
#
node.default['bcpc']['hadoop']['copylog']['namenode'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.log", 
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['namenode_out'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.out", 
    'docopy' => true
}

mount_root = node["bcpc"]["storage"]["disks"]["mount_root"]

%w{hadoop-hdfs-namenode hadoop-mapreduce}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

ruby_block "create namenode directories" do
  block do
    node[:bcpc][:storage][:mounts].each do |d|
      dir = Chef::Resource::Directory.new("#{mount_root}/#{d}/dfs/nn", run_context)
      dir.owner "hdfs"
      dir.group "hdfs"
      dir.mode 0755
      dir.recursive true
      dir.run_action :create

      exe = Chef::Resource::Execute.new("fixup nn owner", run_context)
      exe.command "chown -Rf hdfs:hdfs #{mount_root}/#{d}/dfs"
      exe.only_if { Etc.getpwuid(File.stat("#{mount_root}/#{d}/dfs/").uid).name != "hdfs" }
    end
  end
end

bash "format namenode" do
  code "hdfs namenode -format -nonInteractive -force"
  user "hdfs"
  action :run
  creates lazy { "#{mount_root}/#{node[:bcpc][:storage][:mounts][0]}/dfs/nn/current/VERSION" }
  not_if { lazy{node[:bcpc][:storage][:mounts]}.call.any? { |d| File.exists?("#{mount_root}/#{d}/dfs/nn/current/VERSION") } }
end

service "hadoop-hdfs-namenode" do
  supports :restart => true, :status => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/topology]", :delayed
end

bash "reload hdfs nodes" do
  code "hdfs dfsadmin -refreshNodes"
  user "hdfs"
  action :nothing
  subscribes :run, "template[/etc/hadoop/conf/dfs.exclude]", :delayed
end

###
# We only want to execute this once, as it is setup of dirs within HDFS.
# We'd prefer to do it after all nodes are members of the HDFS system
#
bash "create-hdfs-temp" do
  code "hadoop fs -mkdir /tmp; hadoop fs -chmod -R 1777 /tmp"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /tmp"
end

bash "create-hdfs-user" do
  code "hadoop fs -mkdir /user; hadoop fs -chmod -R 0755 /user"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /user"
end

bash "create-hdfs-history" do
  code "hadoop fs -mkdir /user/history; hadoop fs -chmod -R 1777 /user/history; hadoop fs -chown yarn /user/history"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /user/history"
end

bash "create-hdfs-yarn-log" do
  code "hadoop fs -mkdir -p /var/log/hadoop-yarn; hadoop fs -chown yarn:mapred /var/log/hadoop-yarn"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /var/log/hadoop-yarn"
end
