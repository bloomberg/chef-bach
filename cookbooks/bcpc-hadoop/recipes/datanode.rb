include_recipe 'bcpc-hadoop::hadoop_config'

%w{hadoop-hdfs-datanode
   hadoop-client}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# Setup HDFS datanode bits
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

dep = ["template[/etc/hadoop/conf/hdfs-site.xml]",
       "template[/etc/hadoop/conf/hadoop-env.sh]"]

hadoop_service "hadoop-hdfs-datanode" do
  dependencies dep
  process_identifier "org.apache.hadoop.hdfs.server.datanode.DataNode"
end
