include_recipe 'bcpc-hadoop::hbase_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

node.default['bcpc']['hadoop']['copylog']['region_server'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-0-regionserver-#{node.hostname}.log", 
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['region_server_out'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-0-regionserver-#{node.hostname}.out", 
    'docopy' => true
}

(%w{libsnappy1} +
 %w{hbase hbase-regionserver phoenix}.map{|p| hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release])}).each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w{hbase-client hbase-regionserver phoenix-client}.each do |pkg|
  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

user_ulimit "hbase" do
  filehandle_limit 32769
end

directory "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hbase/lib/native/Linux-amd64-64" do
  recursive true
  action :create
end

link "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hbase/lib/native/Linux-amd64-64/libsnappy.so" do
  to "/usr/lib/libsnappy.so.1"
end

template "/etc/default/hbase" do
  source "hdp_hbase.default.erb"
  mode 0655
  variables(:hbrs_jmx_port => node[:bcpc][:hadoop][:hbase_rs][:jmx][:port])
end

configure_kerberos 'hbasers_kerb' do
  service_name 'hbase'
end

directory '/var/log/hbase/gc' do
  owner 'hbase'
  group 'hbase'
  mode '0755'
  action :create
  notifies :restart, "service[hbase-regionserver]", :delayed
end

template "/etc/init.d/hbase-regionserver" do
  source "hdp_hbase-regionserver-initd.erb"
  mode 0655
end

rs_service_dep = ["template[/etc/hbase/conf/hadoop-metrics2-hbase.properties]",
                  "template[/etc/hbase/conf/hbase-site.xml]",
                  "template[/etc/hbase/conf/hbase-env.sh]",
                  "template[/etc/hbase/conf/hbase-policy.xml]",
                  "template[/etc/hadoop/conf/log4j.properties]",
                  "template[/etc/hadoop/conf/hdfs-site.xml]",
                  "template[/etc/hadoop/conf/core-site.xml]",
                  "bash[hdp-select hbase-regionserver]",
                  "user_ulimit[hbase]",
                  "log[jdk-version-changed]"]

hadoop_service "hbase-regionserver" do
  dependencies rs_service_dep
  process_identifier "org.apache.hadoop.hbase.regionserver.HRegionServer"
end
