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

# Set hbase related zabbix triggers
node.normal['bcpc']['hadoop']['graphite']['service_queries']['hbase_master'] = {
  'hbasenonheapmem' => {
     'type' => "jmx",
     'query' => "memory.NonHeapMemoryUsage_committed",
     'trigger_val' => "max(61,0)",
     'value_type' => 3,
     'trigger_cond' => "=0",
     'trigger_name' => "HBaseMasterAvailability",
     'enable' => true,
     'trigger_dep' => ["NameNodeAvailability"],
     'trigger_desc' => "HBase master seems to be down",
     'severity' => 5,
     'route_to' => "admin"
  },
  'hbaseheapmem' => {
     'type' => "jmx",
     'query' => "memory.HeapMemoryUsage_committed",
     'history_days' => 2,
     'trend_days' => 30,
     'enable' => true
  },
  'numrsservers' => {
     'type' => "jmx",
     'query' => "hbm_server.Master.numRegionServers",
     'trigger_val' => "max(61,0)",
     'value_type' => 3,
     'trigger_cond' => "=0",
     'trigger_name' => "HBaseRSAvailability",
     'enable' => true,
     'trigger_dep' => ["HBaseMasterAvailability"],
     'trigger_desc' => "HBase region server seems to be down",
     'severity' => 5,
     'route_to' => "admin"
  }
}

%w{
hbase
hbase-master
hbase-thrift
libsnappy1
phoenix
}.each do |p|
  package p do
    action :install
  end
end

user_ulimit "hbase" do
  filehandle_limit 32769
end

service "hbase-thrift" do
  action :disable
end 

bash "create-hbase-dir" do
  code "hadoop fs -mkdir -p /hbase; hadoop fs -chown hbase:hadoop /hbase"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /hbase"
end

directory "/usr/hdp/current/hbase-master/lib/native/Linux-amd64-64" do
  recursive true
  action :create
 end

link "/usr/hdp/current/hbase-master/lib/native/Linux-amd64-64/libsnappy.so" do
  to "/usr/lib/libsnappy.so.1"
end

template "/etc/init.d/hbase-master" do
  source "hdp_hbase-master-initd.erb"
  mode 0655
end

service "hbase-master" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hbase/conf/hbase-site.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "user_ulimit[hbase]", :delayed
end
