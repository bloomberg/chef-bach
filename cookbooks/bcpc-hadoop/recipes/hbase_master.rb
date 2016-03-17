include_recipe 'bcpc-hadoop::hbase_config'
include_recipe 'bcpc-hadoop::hbase_queries'

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
  subscribes :restart, "template[/etc/hbase/conf/hadoop-metrics2-hbase.properties]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-site.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-env.sh]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/log4j.properties]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "user_ulimit[hbase]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
end

if node["bcpc"]["hadoop"]["phoenix"]["tracing"]["enabled"]

  template "#{Chef::Config[:file_cache_path]}/trace_table.sql" do
    source "phoenix_trace-table.sql.erb"
    mode "0755"
    action :create
  end

  bash "create_phoenix_trace_table" do
    code <<-EOH
    HBASE_CONF_PATH=/etc/hadoop/conf:/etc/hbase/conf /usr/hdp/current/phoenix-client/bin/sqlline.py "#{node[:bcpc][:hadoop][:zookeeper][:servers].map{ |s| float_host(s[:hostname])}.join(",")}:#{node[:bcpc][:hadoop][:zookeeper][:port]}:/hbase" "#{Chef::Config[:file_cache_path]}/trace_table.sql"
    EOH
    user "hbase"
  end

end
