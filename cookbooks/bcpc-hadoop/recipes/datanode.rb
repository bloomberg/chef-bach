%w{hadoop-yarn-nodemanager
   hadoop-hdfs-datanode
   hadoop-mapreduce
   hadoop-client
   lzop
   hadoop-lzo}.each do |pkg|
  package pkg do
    action :upgrade
  end
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

# Build nodes for Yarn log storage
node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/yarn/" do
    owner "yarn"
    group "yarn"
    mode 0700
    action :create
  end
  %w{mapred-local local logs}.each do |d|
    directory "/disk/#{i}/yarn/#{d}" do
      owner "yarn"
      group "hadoop"
      mode 0700
      action :create
    end
  end
end

%w{hadoop-yarn-nodemanager hadoop-hdfs-datanode}.each do |svc|
  service svc do
    supports :status => true, :restart => true, :reload => false
    action [:enable, :start]
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
  end
end
