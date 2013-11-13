
%w{hadoop-yarn-nodemanager
   hadoop-hdfs-datanode
   hadoop-mapreduce
   hbase-regionserver
   hadoop-client
   impala-server
   impala
   impala-shell}.each do |pkg|
  package pkg do
    action :upgrade
  end
end


node[:bcpc][:hadoop][:mounts].each do |i|

  directory "/disk/#{i}/dfs/dn" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
    recursive true
  end
end

%w{hadoop-yarn-nodemanager hadoop-hdfs-datanode}.each do |svc|
  service svc do
    action :enable
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
  end
end

%w{hbase-regionserver impala-server}.each do |svc|
  service svc do
    action [:enable, :start]
      subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
      subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
      subscribes :restart, "template[/etc/hadoop/conf/hbase-site.xml]", :delayed
  end
end

