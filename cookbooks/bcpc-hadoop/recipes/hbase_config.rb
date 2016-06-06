# vim: tabstop=2:shiftwidth=2:softtabstop=2
# Cookbook Name : bcpc-hadoop
# Recipe Name : hbase_config
# Description : To setup habse related configuration only

directory "/etc/hbase/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

bash "update-hbase-conf-alternatives" do
  code(%Q{
    update-alternatives --install /etc/hbase/conf hbase-conf /etc/hbase/conf.#{node.chef_environment} 50
    update-alternatives --set hbase-conf /etc/hbase/conf.#{node.chef_environment}
  })
end

if get_nodes_for("powerdns", "bcpc").length > 0
 dns_server = node[:bcpc][:management][:vip]
else
 dns_server = node[:bcpc][:dns_servers][0]
end

%w{hadoop-metrics2-hbase.properties}.each do |t|
   template "/etc/hbase/conf/#{t}" do
     source "hb_#{t}.erb"
     mode 0644
     variables(:nn_hosts => node[:bcpc][:hadoop][:nn_hosts],
               :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
               :jn_hosts => node[:bcpc][:hadoop][:jn_hosts],
               :rs_hosts => node[:bcpc][:hadoop][:rs_hosts],
               :master_hosts => node[:bcpc][:hadoop][:hb_hosts],
               :mounts => node[:bcpc][:hadoop][:mounts],
               :hbm_jmx_port => node[:bcpc][:hadoop][:hbase_master][:jmx][:port],
               :hbrs_jmx_port => node[:bcpc][:hadoop][:hbase_rs][:jmx][:port],
               :dns_server => dns_server
     )
  end
end

# thse are rendered as is
%w{ 
  log4j.properties
  hbase-policy.xml }.each do |t|
  template "/etc/hbase/conf/#{t}" do
    source "hb_#{t}.erb"
    mode 0644
  end
end

# thse are rendered as is
%w{
  hbase-client.jaas
  hbase-server.jaas
  regionserver.jaas}.each do |t|
  template "/etc/hbase/conf/#{t}" do
    source "hb_#{t}.erb"
    mode 0644
    only_if { node[:bcpc][:hadoop][:kerberos][:enable] }
  end
end

subnet = node["bcpc"]["management"]["subnet"]

generated_values = {
  'hbase.zookeeper.quorum' => 
    node[:bcpc][:hadoop][:zookeeper][:servers].map{ |s| float_host(s[:hostname])}.join(","),
  'fail.fast.expired.active.master' => 
    node[:bcpc][:hadoop][:hb_hosts].length > 1 ? "true" : "false",
  'hbase.master.dns.nameserver' => dns_server,
  'hbase.master.dns.nameserver' => dns_server,
  'hbase.zookeeper.property.clientPort' => "#{node[:bcpc][:hadoop][:zookeeper][:port]}",
  'fail.fast.expired.active.master' =>
      node[:bcpc][:hadoop][:hb_hosts].length > 1 ? "true" : "false",
  'hbase.master.wait.on.regionservers.mintostart' => 
      "#{node[:bcpc][:hadoop][:rs_hosts].length/2+1}",
  'hbase.regionserver.dns.interface' =>
      node["bcpc"]["networks"][subnet]["floating"]["interface"],
  'hbase.master.dns.interface' =>
      node["bcpc"]["networks"][subnet]["floating"]["interface"]
}

if node[:bcpc][:hadoop][:kerberos][:enable] == true then
  generated_values['hbase.security.authorization'] = 'true'
  generated_values['hbase.superuser'] = node[:bcpc][:hadoop][:hbase][:superusers].join(',')
  generated_values['hbase.coprocessor.region.classes'] = 
    'org.apache.hadoop.hbase.security.token.TokenProvider,' +
    'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint,' +
    'org.apache.hadoop.hbase.security.access.AccessController'
  generated_values['hbase.security.exec.permission.checks'] = 'true'
  generated_values['hbase.coprocessor.regionserver.classes'] = 
    'org.apache.hadoop.hbase.security.access.AccessController'
  generated_values['hbase.coprocessor.master.classes'] = 
    'org.apache.hadoop.hbase.security.access.AccessController'
  generated_values['hbase.security.authentication'] = 'kerberos'
  generated_values['hbase.master.kerberos.principal'] = 
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:principal]}/" +
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
  generated_values['hbase.master.keytab.file'] = 
    "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:keytab]}"
  generated_values['hbase.regionserver.kerberos.principal'] = 
    "#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hbase][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
  generated_values['hbase.regionserver.keytab.file'] = 
    "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hbase][:keytab]}"
  generated_values['hbase.rpc.engine'] = 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
end

site_xml = node[:bcpc][:hadoop][:hbase][:site_xml]
complete_hbase_site_hash = generated_values.merge(site_xml)

template '/etc/hbase/conf/hbase-site.xml' do
  source 'generic_site.xml.erb'
  mode 0644
  variables(:options => complete_hbase_site_hash)
end

# These will become key/value pairs in 'hbase-env.sh'
env_sh = {}
env_sh[:HBASE_PID_DIR] = '"/var/run/hbase"'
env_sh[:HBASE_LOG_DIR] = '"/var/log/hbase"'
env_sh[:HBASE_OPTS] = '" -Djava.net.preferIPv4Stack=true -XX:+UseConcMarkSweepGC"'

env_sh[:HBASE_REGIONSERVER_OPTS] = 
  " -server -XX:ParallelGCThreads=#{[1, (node['cpu']['total'] * node['bcpc']['hadoop']['hbase_rs']['gc_thread']['cpu_ratio']).ceil].max} " +
  " -XX:+UseParNewGC -XX:CMSInitiatingOccupancyFraction=#{node['bcpc']['hadoop']['hbase_rs']['cmsinitiatingoccupancyfraction']} " + 
  "-XX:+UseCMSInitiatingOccupancyOnly -verbose:gc -XX:+PrintHeapAtGC " + 
  "-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps " + 
  "-Xloggc:/var/log/hbase/gc/gc.log-$$-$(hostname)-$(date +'%Y%m%d%H%M').log " +
  "-Xmn#{node['bcpc']['hadoop']['hbase_rs']['xmn']['size']}m " +
  "-Xms#{node['bcpc']['hadoop']['hbase_rs']['xms']['size']}m " + 
  "-Xmx#{node['bcpc']['hadoop']['hbase_rs']['xmx']['size']}m " + 
  "-XX:+ExplicitGCInvokesConcurrent " + 
  "-XX:PretenureSizeThreshold=#{node['bcpc']['hadoop']['hbase_rs']['PretenureSizeThreshold']} " +
  "-XX:+PrintTenuringDistribution -XX:+UseNUMA " + 
  "-XX:+PrintGCApplicationStoppedTime -XX:+UseCompressedOops " + 
  "-XX:+PrintClassHistogram -XX:+PrintGCApplicationConcurrentTime"

if node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] == true then
 env_sh[:HBASE_REGIONSERVER_OPTS] += 
   " -XX:MaxDirectMemorySize=#{node['bcpc']['hadoop']['hbase_rs']['mx_dir_mem']['size']}m"
end

if node[:bcpc][:hadoop].attribute?(:jmx_enabled) and node[:bcpc][:hadoop][:jmx_enabled] then
 env_sh[:HBASE_JMX_BASE] = '"-Dcom.sun.management.jmxremote.ssl=false ' +
   '-Dcom.sun.management.jmxremote.authenticate=false"'
 env_sh[:HBASE_MASTER_OPTS] = '"$HBASE_MASTER_OPTS $HBASE_JMX_BASE ' +
   '-Dcom.sun.management.jmxremote.port=' +
   node[:bcpc][:hadoop][:hbase_master][:jmx][:port].to_s + '"'
 env_sh[:HBASE_REGIONSERVER_OPTS] += ' $HBASE_JMX_BASE' 
end

env_sh[:HBASE_REGIONSERVER_OPTS] = '"' + env_sh[:HBASE_REGIONSERVER_OPTS] + '"'


env_sh[:HBASE_MANAGES_ZK] = '"false"'

template '/etc/hbase/conf/hbase-env.sh' do
  source 'generic_env.sh.erb'
  mode 0644
  variables(:options => env_sh)
end

template "/etc/hbase/conf/regionservers" do
   source "hb_regionservers.erb"
   mode 0644
   variables(:rs_hosts => node[:bcpc][:hadoop][:rs_hosts])
end
