::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)
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

%W(#{hwx_pkg_str('hbase', node[:bcpc][:hadoop][:distribution][:release])}
   #{hwx_pkg_str('phoenix', node[:bcpc][:hadoop][:distribution][:release])}
   libsnappy1).each do |p|
  package p do
    action :upgrade
  end
end

%w{hbase-master
hbase-client
phoenix-client
}.each do |p|
  hdp_select(p, node[:bcpc][:hadoop][:distribution][:active_release])
end

configure_kerberos 'hbase_kerb' do
  service_name 'hbase'
end

user_ulimit "hbase" do
  filehandle_limit 32769
end

service "hbase-thrift" do
  action :disable
end 

bash 'create-hbase-dir' do
  code  <<-EOH
    hdfs dfs -mkdir -p #{node['bcpc']['hadoop']['hbase']['root_dir']}
    hdfs dfs -chown hbase:hadoop #{node['bcpc']['hadoop']['hbase']['root_dir']}
  EOH
  user 'hdfs'
  not_if "hdfs dfs -test -d #{node['bcpc']['hadoop']['hbase']['root_dir']}", :user => 'hdfs'
end

bash 'create-hbase-staging-dir' do
  code <<-EOH
    hdfs dfs -mkdir -p #{node['bcpc']['hadoop']['hbase']['bulkload_staging_dir']}
    hdfs dfs -chown hbase:hadoop #{node['bcpc']['hadoop']['hbase']['bulkload_staging_dir']}
    hdfs dfs -chmod 711 #{node['bcpc']['hadoop']['hbase']['bulkload_staging_dir']}
  EOH
  user 'hdfs'
  not_if "hdfs dfs -test -d #{node['bcpc']['hadoop']['hbase']['bulkload_staging_dir']}", :user => 'hdfs'
end

directory "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hbase/lib/native/Linux-amd64-64" do
  recursive true
  action :create
end

link "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hbase/lib/native/Linux-amd64-64/libsnappy.so" do
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
  subscribes :restart, "bash[hdp-select hbase-master]", :delayed
  subscribes :restart, "user_ulimit[hbase]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
  subscribes :restart, "template[/etc/profile.d/jdk.sh]", :delayed
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
