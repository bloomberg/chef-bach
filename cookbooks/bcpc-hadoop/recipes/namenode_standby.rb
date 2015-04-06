include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::hadoop_config'
require "base64"

#
# Updating node attributes to copy namenode log files to centralized location (HDFS)
#
node.default['bcpc']['hadoop']['copylog']['namenode_standby'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.log",
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['namenode_standby_out'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.out",
    'docopy' => true
}

%w{hadoop-hdfs-namenode hadoop-hdfs-zkfc hadoop-mapreduce}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

ruby_block "hadoop disks" do
  block do
    node[:bcpc][:hadoop][:mounts].each do |d|
      dir = Chef::Resource::Directory.new("/disk/#{d}/dfs/nn", run_context)
      dir.owner "hdfs"
      dir.group "hdfs"
      dir.mode 0755
      dir.recursive true
      dir.run_action :create

      exe = Chef::Resource::Execute.new("fixup nn owner", run_context)
      exe.command "chown -Rf hdfs:hdfs /disk/#{d}/dfs"
      exe.only_if { Etc.getpwuid(File.stat("/disk/#{d}/dfs/").uid).name != "hdfs" }
    end
  end
end

if @node['bcpc']['hadoop']['hdfs']['HA'] == true then
  bash "hdfs namenode -bootstrapStandby -force -nonInteractive" do
    code "hdfs namenode -bootstrapStandby -force -nonInteractive"
    user "hdfs"
    cwd  "/var/lib/hadoop-hdfs"
    action :run
    not_if { lazy { node[:bcpc][:hadoop][:mounts].all? { |d| Dir.entries("/disk/#{d}/dfs/nn/").include?("current") } }.call }
  end  

  service "hadoop-hdfs-zkfc" do
    action [:enable, :start]
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
  end

  service "hadoop-hdfs-namenode" do
    action [:enable, :start]
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/topology]", :delayed
  end
else
  Chef::Log.info "Not running standby namenode services yet -- HA disabled!"
  service "hadoop-hdfs-zkfc" do
    action [:disable, :stop]
  end
  service "hadoop-hdfs-namenode" do
    action [:disable, :stop]
  end
end

bash "reload hdfs nodes" do
  code "hdfs dfsadmin -refreshNodes"
  user "hdfs"
  action :nothing
  subscribes :run, "template[/etc/hadoop/conf/dfs.exclude]", :delayed
end
