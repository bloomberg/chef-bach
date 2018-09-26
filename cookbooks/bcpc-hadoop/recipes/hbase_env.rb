# Chef Attributes for hbase-env.sh file
cpu_total = node['cpu']['total']
cpu_ratio = node['bcpc']['hadoop']['hbase_rs']['gc_thread']['cpu_ratio']
common_opts =
  ' -server -XX:ParallelGCThreads=' + [1, (cpu_total * cpu_ratio).ceil].max.to_s +
  ' -XX:+UseCMSInitiatingOccupancyOnly' \
  ' -XX:+HeapDumpOnOutOfMemoryError' \
  ' -verbose:gc' \
  ' -XX:+PrintHeapAtGC' \
  ' -XX:+PrintGCDetails' \
  ' -XX:+PrintGCTimeStamps' \
  ' -XX:+PrintGCDateStamps' \
  ' -XX:+UseParNewGC' \
  ' -Xloggc:${HBASE_LOG_DIR}/gc/gc-pid-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').log' \
  ' -XX:+UseGCLogFileRotation' \
  ' -XX:NumberOfGCLogFiles=20' \
  ' -XX:GCLogFileSize=20M' \
  ' -XX:+ExplicitGCInvokesConcurrent' \
  ' -XX:+PrintTenuringDistribution' \
  ' -XX:+UseNUMA' \
  ' -XX:+PrintGCApplicationStoppedTime' \
  ' -XX:+UseCompressedOops' \
  ' -XX:+PrintClassHistogram' \
  ' -XX:+PrintGCApplicationConcurrentTime' \
  ' -XX:+ExitOnOutOfMemoryError' \
  " -agentpath:#{node['bcpc-hadoop']['jvmkill']['lib_file']}"

node.default['bcpc']['hadoop']['hbase']['env'].tap do |hbase_env|
  hbase_env['JAVA_HOME'] = node[:bcpc][:hadoop][:java]
  hbase_env['HBASE_PID_DIR'] = '/var/run/hbase'
  hbase_env['HBASE_LOG_DIR'] = '/var/log/hbase'
  hbase_env['HBASE_MANAGES_ZK'] = 'false'

  hbase_env['HBASE_JMX_BASE'] = '-Dcom.sun.management.jmxremote.ssl=false' \
    ' -Dcom.sun.management.jmxremote.authenticate=false'

  hbase_env['HBASE_OPTS'] = '$HBASE_OPTS -Djava.net.preferIPv4Stack=true' \
    " -Djute.maxbuffer=#{node['bcpc']['hadoop']['jute']['maxbuffer']}" \
    ' -XX:+UseConcMarkSweepGC'

  hbase_env['HBASE_MASTER_OPTS'] =
    '$HBASE_MASTER_OPTS' + common_opts +
    " -Djute.maxbuffer=#{node['bcpc']['hadoop']['jute']['maxbuffer']}" \
    ' -Xmn' + node['bcpc']['hadoop']['hbase_master']['xmn']['size'].to_s + 'm' \
    ' -Xms' + node['bcpc']['hadoop']['hbase_master']['xms']['size'].to_s + 'm' \
    ' -Xmx' + node['bcpc']['hadoop']['hbase_master']['xmx']['size'].to_s + 'm' \
    ' -XX:CMSInitiatingOccupancyFraction=' + node['bcpc']['hadoop']['hbase_master']['cmsinitiatingoccupancyfraction'].to_s +
    ' -XX:HeapDumpPath=${HBASE_LOG_DIR}/heap-dump-hm-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof' \
    ' -XX:PretenureSizeThreshold=' + node['bcpc']['hadoop']['hbase_master']['PretenureSizeThreshold'].to_s

  hbase_env['HBASE_REGIONSERVER_OPTS'] =
    '$HBASE_REGION_SERVER_OPTS' + common_opts +
    " -Djute.maxbuffer=#{node['bcpc']['hadoop']['jute']['maxbuffer']}" \
    ' -Xmn' + node['bcpc']['hadoop']['hbase_rs']['xmn']['size'].to_s + 'm' \
    ' -Xms' + node['bcpc']['hadoop']['hbase_rs']['xms']['size'].to_s + 'm' \
    ' -Xmx' + node['bcpc']['hadoop']['hbase_rs']['xmx']['size'].to_s + 'm' \
    ' -XX:CMSInitiatingOccupancyFraction=' + node['bcpc']['hadoop']['hbase_rs']['cmsinitiatingoccupancyfraction'].to_s +
    ' -XX:HeapDumpPath=${HBASE_LOG_DIR}/heap-dump-rs-$$-$(hostname)-$(date +\'%Y%m%d%H%M\').hprof' \
    ' -XX:PretenureSizeThreshold=' + node['bcpc']['hadoop']['hbase_rs']['PretenureSizeThreshold'].to_s
end

if node['bcpc']['hadoop']['hbase']['bucketcache']['enabled'] == true
  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] +
    ' -XX:MaxDirectMemorySize=' + node['bcpc']['hadoop']['hbase_rs']['mx_dir_mem']['size'].to_s + 'm'
end

if node[:bcpc][:hadoop][:kerberos][:enable] == true
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
if node[:bcpc][:hadoop].attribute?(:jmx_enabled) && node[:bcpc][:hadoop][:jmx_enabled]
  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'] + ' $HBASE_JMX_BASE ' \
    ' -Dcom.sun.management.jmxremote.port=' + node[:bcpc][:hadoop][:hbase_master][:jmx][:port].to_s

  node.default['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] =
    node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'] + ' $HBASE_JMX_BASE ' \
    ' -Dcom.sun.management.jmxremote.port=' + node[:bcpc][:hadoop][:hbase_rs][:jmx][:port].to_s
end

node.run_state['hbase_master_generated_java_agents'] = []
node.run_state['hbase_rs_generated_java_agents'] = []
if node[:bcpc][:hadoop][:jmx_agent_enabled]
  # master
  node.run_state['hbase_master_generated_java_agents'].push(
    "#{node['bcpc']['jmxtrans_agent']['lib_file']}=#{node['bcpc']['hadoop']['jmxtrans_agent']['hbase_master']['xml']}"
  )

  # region server
  node.run_state['hbase_rs_generated_java_agents'].push(
    "#{node['bcpc']['jmxtrans_agent']['lib_file']}=#{node['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs']['xml']}"
  )
  node.run_state['hbase_rs_generated_java_agents'].push(
    "#{node['bcpc']['jmxtrans_agent']['lib_file']}=#{node['bcpc']['hadoop']['jmxtrans_agent']['hbase_rs_regions']['xml']}"
  )
end

node.run_state['hbase_master_generated_java_agents'] += node['bcpc']['hadoop']['hbase']['env']['master_java_agents']
node.run_state['hbase_rs_generated_java_agents'] += node['bcpc']['hadoop']['hbase']['env']['regionserver_java_agents']

template '/etc/hbase/conf/hbase-env.sh' do
  source 'hdp_hbase-env.sh.erb'
  mode 0o0644
  variables (
    {
      java_home: node['bcpc']['hadoop']['hbase']['env']['JAVA_HOME'],
      hbase_pid_dir: node['bcpc']['hadoop']['hbase']['env']['HBASE_PID_DIR'],
      hbase_log_dir: node['bcpc']['hadoop']['hbase']['env']['HBASE_LOG_DIR'],
      hbase_manages_zk: node['bcpc']['hadoop']['hbase']['env']['HBASE_MANAGES_ZK'],
      hbase_jmx_base: node['bcpc']['hadoop']['hbase']['env']['HBASE_JMX_BASE'],
      hbase_opts: node['bcpc']['hadoop']['hbase']['env']['HBASE_OPTS'],
      hbase_master_opts: node['bcpc']['hadoop']['hbase']['env']['HBASE_MASTER_OPTS'],
      hbase_regionserver_opts: node['bcpc']['hadoop']['hbase']['env']['HBASE_REGIONSERVER_OPTS'],
      master_java_agents: node.run_state['hbase_master_generated_java_agents'].uniq,
      regionserver_java_agents: node.run_state['hbase_rs_generated_java_agents'].uniq
    }
  )
end
