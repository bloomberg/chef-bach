node.default['bcpc']['hadoop']['hbase']['env'] = {}

# Chef Attributes for hbase-env.sh file
cpu_total = node['cpu']['total']
cpu_ratio = node['bcpc']['hadoop']['hbase_rs']['gc_thread']['cpu_ratio']
common_opts =
  ' -server -XX:ParallelGCThreads=' +
      [1, (cpu_total * cpu_ratio).ceil].max.to_s +
  ' -XX:+UseCMSInitiatingOccupancyOnly' +
  ' -XX:+HeapDumpOnOutOfMemoryError' +
  ' -verbose:gc' +
  ' -XX:+PrintHeapAtGC' +
  ' -XX:+PrintGCDetails' +
  ' -XX:+PrintGCTimeStamps' +
  ' -XX:+PrintGCDateStamps' +
  ' -XX:+UseParNewGC' +
  ' -Xloggc:${HBASE_LOG_DIR}/gc/gc-pid-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log' +
  ' -Xmn' + node['bcpc']['hadoop']['hbase_rs']['xmn']['size'].to_s + 'm' +
  ' -Xms' + node['bcpc']['hadoop']['hbase_rs']['xms']['size'].to_s + 'm' +
  ' -Xmx' + node['bcpc']['hadoop']['hbase_rs']['xmx']['size'].to_s + 'm' +
  ' -XX:+ExplicitGCInvokesConcurrent' +
  ' -XX:+PrintTenuringDistribution' +
  ' -XX:+UseNUMA' +

  ' -XX:+PrintGCApplicationStoppedTime' +
  ' -XX:+UseCompressedOops' +
  ' -XX:+PrintClassHistogram' +
  ' -XX:+PrintGCApplicationConcurrentTime' +
  ' -XX:+ExitOnOutOfMemoryError'

node.default['bcpc']['hadoop']['hbase']['env'].tap do |hbase_env|
  hbase_env['JAVA_HOME'] = node[:bcpc][:hadoop][:java]
  hbase_env['HBASE_PID_DIR'] = '/var/run/hbase'
  hbase_env['HBASE_LOG_DIR'] = '/var/log/hbase'
  hbase_env['HBASE_MANAGES_ZK'] = 'false'

  hbase_env['HBASE_JMX_BASE'] = '-Dcom.sun.management.jmxremote.ssl=false' +
    ' -Dcom.sun.management.jmxremote.authenticate=false'

  hbase_env['HBASE_OPTS'] = '$HBASE_OPTS -Djava.net.preferIPv4Stack=true' +
    ' -XX:+UseConcMarkSweepGC'

  hbase_env['HBASE_MASTER_OPTS'] =
    '$HBASE_MASTER_OPTS' +
     common_opts +
    ' -XX:CMSInitiatingOccupancyFraction=' +
      node['bcpc']['hadoop']['hbase_master']['cmsinitiatingoccupancyfraction'].to_s +
    ' -XX:HeapDumpPath=${HBASE_LOG_DIR}/heap-dump-hm-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof' +
    ' -XX:PretenureSizeThreshold=' +
      node['bcpc']['hadoop']['hbase_master']['PretenureSizeThreshold'].to_s

  hbase_env['HBASE_REGIONSERVER_OPTS'] =
    '$HBASE_REGION_SERVER_OPTS' +
    common_opts +
    ' -XX:CMSInitiatingOccupancyFraction=' +
      node['bcpc']['hadoop']['hbase_rs']['cmsinitiatingoccupancyfraction'].to_s +
    ' -XX:HeapDumpPath=${HBASE_LOG_DIR}/heap-dump-rs-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof' +
    ' -XX:PretenureSizeThreshold=' +
      node['bcpc']['hadoop']['hbase_rs']['PretenureSizeThreshold'].to_s
end

if node["bcpc"]["hadoop"]["hbase"]["bucketcache"]["enabled"] == true then
  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] =
   node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] +
   ' -XX:MaxDirectMemorySize=' +
     ((node.memory.total.to_i / 1024 ) * node["bcpc"]["hadoop"]["hbase_rs"]["mx_dir_mem"]["size_by_ratio"]).floor.to_s + 'm'
  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] =
   node['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] +
   ' -XX:MaxDirectMemorySize=' +
     node['bcpc']['hadoop']['hbase_master']['mx_dir_mem']['size'].to_s + 'm'
end

if node[:bcpc][:hadoop][:kerberos][:enable] == true then
    node.default['bcpc']['hadoop']['hbase']['env']['HBASE_OPTS'] =
      node['bcpc']['hadoop']['hbase']['env']['HBASE_OPTS'] +
      ' -Djava.security.auth.login.config=/etc/hbase/conf/hbase-client.jaas'
    node.default['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] =
      node['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] +
      ' -Djava.security.auth.login.config=/etc/hbase/conf/hbase-server.jaas'
    node.default['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] =
      node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] +
      ' -Djava.security.auth.login.config=/etc/hbase/conf/regionserver.jaas'
end

#
# HBASE Master and RegionServer env.sh variables are updated with JMX related options when JMX is enabled
#
if node[:bcpc][:hadoop].attribute?(:jmx_enabled) and node[:bcpc][:hadoop][:jmx_enabled] then
  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] +
    ' $HBASE_JMX_BASE ' +
    ' -Dcom.sun.management.jmxremote.port=' +
      node[:bcpc][:hadoop][:hbase_master][:jmx][:port].to_s
   node.default['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] +
    ' $HBASE_JMX_BASE ' +
    ' -Dcom.sun.management.jmxremote.port=' +
      node[:bcpc][:hadoop][:hbase_rs][:jmx][:port].to_s
end

template '/etc/hbase/conf/hbase-env.sh' do
  source 'generic_env.sh.erb'
  mode 0644
  variables(:options => node['bcpc']['hadoop']['hbase']['env'])
end
