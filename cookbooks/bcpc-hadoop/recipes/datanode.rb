
%w{hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce hadoop-client}.each do |pkg|
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

%w{hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce}.each do |svc|
  service svc do 
    action [:enable, :restart]
  end
end


###
# We only want to execute this once, as it is setup of dirs within HDFS. 
# We'd prefer to do it after all nodes are members of the HDFS system
#
c1 = bash "create-hdfs-temp" do
  code "hdfs hadoop fs -mkdir /tmp; hdfs hadoop fs -chmod -R 1777 /tmp"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /tmp"
end

c2 = bash "create-hdfs-history" do
  code "hdfs hadoop fs -mkdir /user; hdfs hadoop fs -chmod -R 0755 /user"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /user"
end

c3 = bash "create-hdfs-history" do
  code "hdfs hadoop fs -mkdir /user/history; hdfs hadoop fs -chmod -R 1777 /user/history; hdfs hadoop fs -chown yarn /user/history"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /user/history"
end

c4 = bash "create-hdfs-yarn-log" do
  code "hdfs hadoop fs -mkdir /var/log/hadoop-yarn; hdfs hadoop fs chown yarn:mapred /var/log/hadoop-yarn"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /var/log/hadoop-yarn"
end

if get_hadoop_workers.length == node[:bcpc][:hadoop][:min_node_count] then
  c1.run_action(:run)
  c2.run_action(:run)
  c3.run_action(:run)
  c4.run_action(:run)
end
