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

#
# Add common hbase-site.xml properties
#
generated_values = {
  'hbase.zookeeper.quorum' => 
    node[:bcpc][:hadoop][:zookeeper][:servers].map{ |s| float_host(s[:hostname])}.join(","),
  'hbase.master.dns.nameserver' => dns_server,
  'hbase.master.dns.nameserver' => dns_server,
  'hbase.zookeeper.property.clientPort' => "#{node[:bcpc][:hadoop][:zookeeper][:port]}",
  'hbase.master.wait.on.regionservers.mintostart' => 
      "#{node[:bcpc][:hadoop][:rs_hosts].length/2+1}",
  'hbase.master.hostname' => float_host(node[:fqdn]),
  'hbase.regionserver.hostname' => float_host(node[:fqdn]),
  'hbase.regionserver.dns.interface' =>
      node["bcpc"]["networks"][subnet]["floating"]["interface"],
  'hbase.master.dns.interface' =>
      node["bcpc"]["networks"][subnet]["floating"]["interface"],
  'dfs.client.read.shortcircuit' => node["bcpc"]["hadoop"]["hbase"]["shortcircuit"]["read"].to_s
}

#
# Any hbase-site.xml property related to Kerberos need to go here
#
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

#
# If HDFS short circuit read is enabled properties in this section will be added to hbase-site.xml
#
if node["bcpc"]["hadoop"]["hbase"]["shortcircuit"]["read"] == true then
  generated_values['dfs.domain.socket.path'] =  '/var/run/hadoop-hdfs/dn._PORT'
  generated_values['dfs.client.read.shortcircuit.buffer.size'] = node["bcpc"]["hadoop"]["hbase"]["dfs"]["client"]["read"]["shortcircuit"]["buffer"]["size"].to_s
end

#
# If HBASE bucket cache is enabled the properties from this section will be included in hbase-site.xml
#
bucketcache_size = (node["bcpc"]["hadoop"]["hbase_rs"]["mx_dir_mem"]["size"] -  node["bcpc"]["hadoop"]["hbase_rs"]["hdfs_dir_mem"]["size"]).floor
if node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] == true then
  generated_values['hbase.regionserver.global.memstore.upperLimit'] = node["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["upperlimit"].to_s
  generated_values['hfile.block.cache.size'] = node["bcpc"]["hadoop"]["hbase"]["blockcache"]["size"].to_s
  generated_values['hbase.bucketcache.size'] = bucketcache_size
  generated_values['hbase.bucketcache.ioengine '] = node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["ioengine"]
  generated_values['hbase.bucketcache.combinedcache.enabled'] = true
end

#
# if HBASE region replication is enabled the properties in this section will be included in hbase-site.xml
#
if node["bcpc"]["hadoop"]["hbase"]["region"]["replication"]["enabled"] == true then
  generated_values['hbase.regionserver.storefile.refresh.period'] = node["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["period"]
  generated_values['hbase.region.replica.replication.enabled'] = node["bcpc"]["hadoop"]["hbase"]["region"]["replication"]["enabled"]
  generated_values['hbase.master.hfilecleaner.ttl'] = node["bcpc"]["hadoop"]["hbase_master"]["hfilecleaner"]["ttl"]
  generated_values['hbase.meta.replica.count'] = node["bcpc"]["hadoop"]["hbase"]["meta"]["replica"]["count"]
  generated_values['hbase.regionserver.storefile.refresh.all'] = node["bcpc"]["hadoop"]["hbase_rs"]["storefile"]["refresh"]["all"]
  generated_values['hbase.region.replica.storefile.refresh.memstore.multiplier'] = node["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["storefile"]["refresh"]["memstore"]["multiplier"]
  generated_values['hbase.region.replica.wait.for.primary.flush'] = node["bcpc"]["hadoop"]["hbase"]["region"]["replica"]["wait"]["for"]["primary"]["flush"]
  generated_values['hbase.regionserver.global.memstore.lowerLimit'] = node["bcpc"]["hadoop"]["hbase_rs"]["memstore"]["lowerlimit"]
  generated_values['hbase.hregion.memstore.block.multiplier'] = node["bcpc"]["hadoop"]["hbase"]["hregion"]["memstore"]["block"]["multiplier"]
  generated_values['hbase.ipc.client.specificThreadForWriting'] = node["bcpc"]["hadoop"]["hbase"]["ipc"]["client"]["specificthreadforwriting"]
  generated_values['hbase.client.primaryCallTimeout.get'] = node["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["get"]
  generated_values['hbase.client.primaryCallTimeout.multiget'] = node["bcpc"]["hadoop"]["hbase"]["client"]["primarycalltimeout"]["multiget"]
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
env_sh[:HBASE_OPTS] = '-Djava.net.preferIPv4Stack=true -XX:+UseConcMarkSweepGC '
env_sh[:HBASE_JMX_BASE] = '"-Dcom.sun.management.jmxremote.ssl=false ' +
  '-Dcom.sun.management.jmxremote.authenticate=false"'

#
# Common env.sh options relevant to HBASE region servers
#
env_sh[:HBASE_REGIONSERVER_OPTS] = 
  "-server -XX:ParallelGCThreads=#{[1, (node['cpu']['total'] * node['bcpc']['hadoop']['hbase_rs']['gc_thread']['cpu_ratio']).ceil].max} " +
  " -XX:+UseParNewGC  -XX:+UseConcMarkSweepGC " +
  "-XX:CMSInitiatingOccupancyFraction=#{node['bcpc']['hadoop']['hbase_rs']['cmsinitiatingoccupancyfraction']} " + 
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

#
# Common env.sh options relevant to HBASE master
#
env_sh[:HBASE_MASTER_OPTS] =
  "-server -XX:ParallelGCThreads=#{[1, (node['cpu']['total'] * node['bcpc']['hadoop']['hbase_master']['gc_thread']['cpu_ratio']).ceil].max} " +
  "-XX:+UseParNewGC -XX:+UseConcMarkSweepGC " +
  "-XX:CMSInitiatingOccupancyFraction=#{node['bcpc']['hadoop']['hbase_master']['cmsinitiatingoccupancyfraction']} " +
  "-XX:+UseCMSInitiatingOccupancyOnly -verbose:gc -XX:+PrintHeapAtGC " +
  "-XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps " +
  "-Xloggc:/var/log/hbase/gc/gc.log-$$-$(hostname)-$(date +'%Y%m%d%H%M').log " +
  "-Xmn#{node['bcpc']['hadoop']['hbase_master']['xmn']['size']}m " +
  "-Xms#{node['bcpc']['hadoop']['hbase_master']['xms']['size']}m " +
  "-Xmx#{node['bcpc']['hadoop']['hbase_master']['xmx']['size']}m " +
  "-XX:+ExplicitGCInvokesConcurrent " +
  "-XX:PretenureSizeThreshold=#{node['bcpc']['hadoop']['hbase_master']['PretenureSizeThreshold']} " +
  "-XX:+PrintTenuringDistribution -XX:+UseNUMA " +
  "-XX:+PrintGCApplicationStoppedTime -XX:+UseCompressedOops " +
  "-XX:+PrintClassHistogram -XX:+PrintGCApplicationConcurrentTime"
#
# HBASE Master and RegionServer env.sh variables are updated with relevant JAAS file entries when Kerberos is enabled
#
if node[:bcpc][:hadoop][:kerberos][:enable] == true then
 env_sh[:HBASE_OPTS] += ' -Djava.security.auth.login.config=/etc/hbase/conf/hbase-client.jaas'
 env_sh[:HBASE_MASTER_OPTS] += ' -Djava.security.auth.login.config=/etc/hbase/conf/hbase-server.jaas'
 env_sh[:HBASE_REGIONSERVER_OPTS] += ' -Djava.security.auth.login.config=/etc/hbase/conf/regionserver.jaas'
end

#
# HBASE RegionServer JVM direct memory size is updated if BucketCache is enabled
#
if node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] == true then
 env_sh[:HBASE_REGIONSERVER_OPTS] += 
   " -XX:MaxDirectMemorySize=#{node['bcpc']['hadoop']['hbase_rs']['mx_dir_mem']['size']}m"
end

#
# HBASE Master and RegionServer env.sh variables are updated with JMX related options when JMX is enabled
#
if node[:bcpc][:hadoop].attribute?(:jmx_enabled) and node[:bcpc][:hadoop][:jmx_enabled] then
 env_sh[:HBASE_MASTER_OPTS] += ' $HBASE_JMX_BASE ' +
   '-Dcom.sun.management.jmxremote.port=' +
   node[:bcpc][:hadoop][:hbase_master][:jmx][:port].to_s
 env_sh[:HBASE_REGIONSERVER_OPTS] += ' $HBASE_JMX_BASE ' +
   '-Dcom.sun.management.jmxremote.port=' +
   node[:bcpc][:hadoop][:hbase_rs][:jmx][:port].to_s 
end

#
# At the end sealing the HBASE_OPTS, MASTER_OPTS and REGIONSERVER_OPTS in quotes
#
env_sh[:HBASE_OPTS] = '"' + env_sh[:HBASE_OPTS] + '"'
env_sh[:HBASE_MASTER_OPTS] = '"' + env_sh[:HBASE_MASTER_OPTS] + '"'
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
