include_recipe 'bcpc-hadoop::hadoop_config'

%w{hadoop-hdfs-datanode
   hadoop-client
   sqoop
   lzop
   hadoop-lzo}.each do |pkg|
  package pkg do
    action :upgrade
  end
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

%w{hive hcatalog libmysql-java}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

link "/usr/lib/hive/lib/mysql.jar" do
  to "/usr/share/java/mysql.jar"
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
