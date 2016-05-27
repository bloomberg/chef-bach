default["bcpc"]["hadoop"]["yarn"]["fairsharepreemptiontimeout"] = 150
default['bcpc']['hadoop']['yarn']['historyserver']['heap']["size"] = 128
default['bcpc']['hadoop']['yarn']['historyserver']['heap']["ratio"] = 0
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_memory"]["ratio"] = 0.5
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_memory"]["size"] = nil
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_vcpu"]["ratio"] = 0.5
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_vcpu"]["count"] = nil
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["port"] = 45454
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["jmx"]["port"] = 3131
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["port"] = 8032
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["jmx"]["port"] = 3131
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["fair"]["min-vcores"] = 2

default[:bcpc][:hadoop][:yarn][:env_sh].tap do |env_sh|
  env_sh[:YARN_LOG_DIR] = '/var/log/hadoop-yarn'
  env_sh[:YARN_PID_DIR] = '/var/run/hadoop-yarn'
  env_sh[:YARN_IDENT_STRING] = 'yarn'
  env_sh[:HADOOP_YARN_USER] = 'yarn'
  env_sh[:YARN_CONF_DIR] = '/etc/hadoop/conf'
  env_sh[:JAVA_HOME] = node[:bcpc][:hadoop][:java]
  env_sh[:JAVA] = File.join(env_sh[:JAVA_HOME], 'bin', 'java')
  env_sh[:YARN_HEAPSIZE] = '1000' # megabytes
  env_sh[:JAVA_HEAP_MAX] = '1000' # megabytes
  env_sh[:YARN_LOGFILE] = 'yarn.log'
  env_sh[:YARN_POLICYFILE] =  'hadoop-policy.xml'

  env_sh[:YARN_OPTS] = '"' +
    '-Dhadoop.log.dir=#{env_sh[:YARN_LOG_DIR]} ' +
    '-Dyarn.log.dir=#{env_sh[:YARN_LOG_DIR]} " '
    '-Dhadoop.log.file=#{env_sh[:YARN_LOGFILE]} ' +
    '-Dyarn.log.dir=#{env_sh[:YARN_LOGFILE]} ' +
    '-Dyarn.id.str=#{env_sh[:YARN_IDENT_STRING]} ' +
    '-Dhadoop.root.logger=INFO,CONSOLE ' +
    '-Dyarn.root.logger=INFO,CONSOLE ' +
    '-Dyarn.policy.file=#{env_sh[:YARN_POLICYFILE]} ' +
    '-Djute.maxbuffer=#{node[:bcpc][:hadoop][:jute][:maxbuffer]}' +
    '"'

  env_sh[:YARN_NODEMANAGER_OPTS] = '"' +
    '-Dcom.sun.management.jmxremote.ssl=false ' +
    '-Dcom.sun.management.jmxremote.authenticate=false ' +
    '-Dcom.sun.management.jmxremote.port=' +
    node[:bcpc][:hadoop][:yarn][:nodemanager][:jmx][:port].to_s +
   '"'

  env_sh[:YARN_NODEMANAGER_OPTS] = '"' +
    '-Dcom.sun.management.jmxremote.ssl=false ' +
    '-Dcom.sun.management.jmxremote.authenticate=false ' +
    '-Dcom.sun.management.jmxremote.port=' +
    node[:bcpc][:hadoop][:yarn][:resourcemanager][:jmx][:port].to_s +
    '"' 
end

default[:bcpc][:hadoop][:yarn][:site_xml].tap do |site_xml|
  site_xml['yarn.application.classpath'] =
    [
     '/etc/hadoop/conf',
     '/usr/hdp/current/hadoop-client/*',
     '/usr/hdp/current/hadoop-client/lib/*',
     '/usr/hdp/current/hadoop-hdfs-client/*',
     '/usr/hdp/current/hadoop-hdfs-client/lib/*',
     '/usr/hdp/current/hadoop-yarn-client/*',
     '/usr/hdp/current/hadoop-yarn-client/lib/*'
    ].join(',')

  site_xml['yarn.log-aggregation-enable'] = true
  site_xml['yarn.log-aggregation.retain-seconds'] = 60 * 60 * 24 * 31

  ynla = 'yarn.nodemanager.log-aggregation'
  site_xml["#{ynla}.roll-monitoring-interval-seconds"] = 1800
  site_xml["#{ynla}.compression-type"] = 'gz'


  site_xml["yarn.nodemanager.container-executor.class"] =
    'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor'

  lce = 'yarn.nodemanager.linux-container-executor'
  site_xml["#{lce}.group"] = 'yarn'
  site_xml["#{lce}.nonsecure-mode.limit-users"] = false
  site_xml["#{lce}.resources-handler.class"] =
    'org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler'
  site_xml["#{lce}.cgroups.mount-path"] = '/sys/fs/cgroup/'

  site_xml['yarn.nodemanager.remote-app-log-dir'] = '/var/log/hadoop-yarn/apps'
  
  yarn_max_memory = lambda do
    avail_memory =
      node['bcpc']['hadoop']['yarn']['nodemanager']['avail_memory']

    avail_memory['size'] ||
      [1024, (node['memory']['total'].to_i * avail_memory['ratio']/1024).floor].max
  end

  site_xml['yarn.nodemanager.resource.memory-mb'] = yarn_max_memory.call

  avail_vcpu = lambda do
    node['bcpc']['hadoop']['yarn']['nodemanager']['avail_vcpu']
  end

  site_xml['yarn.nodemanager.resource.cpu-vcores'] =
    (avail_vcpu.call['cores'] ||
      [1, (node['cpu']['total'] * avail_vcpu.call['ratio']).floor].max)

  site_xml['yarn.nodemanager.resource.percentage-physical-cpu-limit'] =
    if avail_vcpu.call['count']
      (avail_vcpu.call['count'] / node['cpu']['total'])
    else
      (avail_vcpu.call['ratio'] * 100).floor
    end

  site_xml['yarn.nodemanager.vmem-check-enabled'] = false
                        
  site_xml['yarn.resourcemanager.nodes.exclude-path'] =
    '/etc/hadoop/conf/yarn.exclude'

  site_xml['yarn.resourcemanager.scheduler.class'] =  
    'org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler'

  site_xml['yarn.scheduler.fair.preemption'] = true
  
  site_xml['yarn.scheduler.minimum-allocation-mb'] = 256
  
  site_xml['yarn.scheduler.maximum-allocation-mb'] = yarn_max_memory.call

  site_xml['yarn.timeline-service.client.max-retries'] = 0
end

### Delete these. (start) ###

#
# These properties are used exactly once in generated values, so they've been
# replaced by constants in yarn_config.rb
#
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["yarn.client.failover-sleep-base-ms"] = 150
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["recovery"]["enabled"] = true
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["store"]["class"] = "org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore"
default["bcpc"]["hadoop"]["yarn"]["client"]["failover-proxy-provider"] = "org.apache.hadoop.yarn.client.ConfiguredRMFailoverProxyProvider"

#
# All of these properties are used exactly once, but can be replaced
# by defaults in [:bcpc][:hadoop][:yarn][:site_xml]
#
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["remote-app-log-dir"] = "/var/log/hadoop-yarn/apps"
default["bcpc"]["hadoop"]["yarn"]["log-aggregation-enable"] = true
default["bcpc"]["hadoop"]["yarn"]["log-aggregation_retain-seconds"] = 60*60*24*31
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["log-aggregation"]["roll-monitoring-interval-seconds"] = 1800
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["log-aggregation"]["compression-type"] = "gz"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["container-executor"]["class"] = "org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor"
default["bcpc"]["hadoop"]["yarn.nodemanager.linux-container-executor.group"] = "yarn"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["linux-container-executor"]["nonsecure-mode"]["limit-users"] = false
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["linux-container-executor"]["resources-handler"]["class"] = "org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["linux-container-executor"]["cgroups"]["mount-path"] = "/sys/fs/cgroup/"
default['bcpc']['hadoop']['yarn']['nodemanager']['vmem-check-enabled'] = false
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["nodes"]["exclude-path"] = "/etc/hadoop/conf/yarn.exclude"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["class"] = "org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["fair"]["preemption"] = true
default['bcpc']['hadoop']['yarn']['timeline-service']['client']['max-retries'] = 0
