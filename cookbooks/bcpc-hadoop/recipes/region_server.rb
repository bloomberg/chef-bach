include_recipe 'bcpc-hadoop::hbase_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

(%w(libsnappy1) + %w(hbase hbase-regionserver phoenix).map do |p|
  hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release])
end).each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w(hbase-client hbase-regionserver phoenix-client).each do |symlink|
  hdp_select(symlink, node[:bcpc][:hadoop][:distribution][:active_release])
end

user_ulimit 'hbase' do
  filehandle_limit 65_536
end

directory "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}"\
          '/hbase/lib/native/Linux-amd64-64' do
  recursive true
  action :create
end

link "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}"\
     '/hbase/lib/native/Linux-amd64-64/libsnappy.so' do
  to '/usr/lib/libsnappy.so.1'
end

template '/etc/default/hbase' do
  source 'hdp_hbase.default.erb'
  mode '0655'
  variables(hbrs_jmx_port: node[:bcpc][:hadoop][:hbase_rs][:jmx][:port])
end

configure_kerberos 'region_server_spnego' do
  service_name 'spnego'
end

configure_kerberos 'hbasers_kerb' do
  service_name 'hbase'
end

directory '/var/log/hbase/gc' do
  owner 'hbase'
  group 'hbase'
  mode '0755'
  action :create
end

template '/etc/init.d/hbase-regionserver' do
  source 'hdp_hbase-regionserver-initd.erb'
  mode '0655'
end

service 'hbase-regionserver' do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
end

locking_resource 'hbase-regionserver' do
  process_identifier = 'org.apache.hadoop.hbase.regionserver.HRegionServer'
  resource 'service[hbase-regionserver]'
  process_pattern {command_string process_identifier
                   user 'hbase'
                   full_cmd true}
  perform :restart
  action :serialize_process
  subscribes :serialize, 'link[/etc/init.d/hbase-regionserver]', :delayed
  subscribes :serialize, 'template[/etc/hbase/conf/hadoop-metrics2-hbase.properties]', :delayed
  subscribes :serialize, 'template[/etc/hbase/conf/hbase-site.xml]', :delayed
  subscribes :serialize, 'template[/etc/hbase/conf/hbase-env.sh]', :delayed
  subscribes :serialize, 'template[/etc/hbase/conf/hbase-policy.xml]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/log4j.properties]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/hdfs-site.xml]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/core-site.xml]', :delayed
  subscribes :serialize, 'bash[hdp-select hbase-regionserver]', :delayed
  subscribes :serialize, 'directory[/var/log/hbase/gc]', :delayed
  subscribes :serialize, 'user_ulimit[hbase]', :delayed
  subscribes :serialize, 'log[jdk-version-changed]', :delayed
end
