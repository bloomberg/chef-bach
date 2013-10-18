
%w{hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-mapreduce hadoop-client}.each do |pkg|
  package pkg do
    action :upgrade
  end
end


(1..4).each do |i|

  directory "/disk#{i}/yarn/logs" do
    owner "yarn"
    group "yarn"
    mode 0700
    action :create
    recursive true
  end

  directory "/disk#{i}/yarn/local" do
    owner "yarn"
    group "yarn"
    mode 0700
    action :create
    recursive true
  end

  directory "/disk#{i}/dfs/dn" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
    recursive true
  end
end

bash "create-hdfs-temp" do
  code "hdfs hadoop fs -mkdir /tmp; hdfs hadoop fs -chmod -R 1777 /tmp"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /tmp"
end

bash "create-hdfs-history" do
  code "hdfs hadoop fs -mkdir /user/history; hdfs hadoop fs -chmod -R 1777 /user/history; hdfs hadoop fs -chown yarn /user/history"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /user/history"
end

bash "create-hdfs-yarn-log" do
  code "hdfs hadoop fs -mkdir /var/log/hadoop-yarn; hdfs hadoop fs chown yarn:mapred /var/log/hadoop-yarn"
  user "hdfs"
  action :nothing
  not_if "sudo -u hdfs hadoop fs -test /var/log/hadoop-yarn"
end

service "hadoop-yarn-nodemanager" do
  action [:enable, :restart]
end

