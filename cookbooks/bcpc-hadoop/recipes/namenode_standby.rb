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

directory "/var/log/hadoop-hdfs/gc/" do
  user "hdfs"
  group "hdfs"
  action :create
  notifies :restart, "service[hadoop-hdfs-namenode]", :delayed
end

user_ulimit "hdfs" do
  filehandle_limit 32769
  process_limit 65536
end

node[:bcpc][:hadoop][:mounts].each do |d|
  directory "/disk/#{d}/dfs/nn" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

  execute "fixup nn owner" do
    command "chown -Rf hdfs:hdfs /disk/#{d}/dfs/"
    only_if { Etc.getpwuid(File.stat("/disk/#{d}/dfs/").uid).name != "hdfs" }
  end
end

template "/etc/init.d/hadoop-hdfs-namenode" do
  source "hdp_hadoop-hdfs-namenode-initd.erb"
  mode 0655
end

template "/etc/init.d/hadoop-hdfs-zkfc" do
  source "hdp_hadoop-hdfs-zkfc-initd.erb"
  mode 0655
end

if @node['bcpc']['hadoop']['hdfs']['HA'] == true then
  bash "hdfs namenode -bootstrapStandby -force -nonInteractive" do
    code "hdfs namenode -bootstrapStandby -force -nonInteractive"
    user "hdfs"
    cwd  "/var/lib/hadoop-hdfs"
    action :run
    not_if { node[:bcpc][:hadoop][:mounts].all? { |d| Dir.entries("/disk/#{d}/dfs/nn/").include?("current") } }
  end  

  service "hadoop-hdfs-zkfc" do
    action [:enable, :start]
    supports :status => true, :restart => true, :reload => false
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  end

  service "hadoop-hdfs-namenode" do
    action [:enable, :start]
    supports :status => true, :restart => true, :reload => false
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/topology]", :delayed
    subscribes :restart, "user_ulimit[hdfs]", :delayed
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
