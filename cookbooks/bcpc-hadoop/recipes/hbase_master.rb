include_recipe 'bcpc-hadoop::hbase_config'

#
# Updating node attributes to copy HBase master log file to centralized location (HDFS)
#
node.default['bcpc']['hadoop']['copylog']['hbase_master'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-master-#{node.hostname}.log",
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['hbase_master_out'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-master-#{node.hostname}.out",
    'docopy' => true
}

%w{
hbase
hbase-master
hbase-thrift
libsnappy1
}.each do |p|
  package p do
    action :install
  end
end

service "hbase-thrift" do
  action :disable
end 

bash "create-hbase-dir" do
  code "hadoop fs -mkdir -p /hbase; hadoop fs -chown hbase:hadoop /hbase"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /hbase"
end

directory "/usr/lib/hbase/lib/native/Linux-amd64-64/" do
  recursive true
  action :create
end

link "/usr/lib/hbase/lib/native/Linux-amd64-64/libsnappy.so.1" do
  to "/usr/lib/libsnappy.so.1"
end

service "hbase-master" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hbase/conf/hbase-site.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-env.sh]", :delayed
end
