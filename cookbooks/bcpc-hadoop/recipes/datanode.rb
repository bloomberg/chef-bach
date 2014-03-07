
%w{hadoop-yarn-nodemanager
   hadoop-hdfs-datanode
   hadoop-mapreduce
   hbase-regionserver
   hadoop-client
   hadoop-lzo
   hive}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# Build nodes for HDFS storage
node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/dfs/dn" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
    recursive true
  end
end

# Build nodes for Yarn log storage
node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/yarn/local" do
    owner "yarn"
    group "yarn"
    mode 0700
    action :create
    recursive true
  end
  directory "/disk/#{i}/yarn/logs" do
    owner "yarn"
    group "yarn"
    mode 0700
    action :create
    recursive true
  end
end

if node[:bcpc][:hadoop][:mounts].length <= node[:bcpc][:hadoop][:hdfs][:failed_volumes_tolerated]
  Chef::Application.fatal!('You have fewer node[:bcpc][:hadoop][:disks] than node[:bcpc][:hadoop][:hdfs][:failed_volumes_tolerated]! See comments of HDFS-4442.')
end

%w{libmysql-java}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

link "/usr/lib/hive/lib/mysql.jar" do
  to "/usr/share/java/mysql.jar"
end

%w{hadoop-yarn-nodemanager hadoop-hdfs-datanode}.each do |svc|
  service svc do
    action [:enable, :start]
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
  end
end

%w{hbase-regionserver}.each do |svc|
  service svc do
    action [:enable, :start]
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hbase-site.xml]", :delayed
  end
end

