require 'shellwords'

default[:bcpc][:hadoop][:yarn][:env_sh].tap do |env_sh|
  env_sh[:YARN_LOG_DIR] = '/var/log/hadoop-yarn'
  env_sh[:YARN_PID_DIR] = '/var/run/hadoop-yarn'
  env_sh[:YARN_IDENT_STRING] = 'yarn'
  env_sh[:HADOOP_YARN_USER] = 'yarn'
  env_sh[:YARN_CONF_DIR] = '$YARN_HOME/conf'
  env_sh[:JAVA_HOME] = node[:bcpc][:hadoop][:java]
  env_sh[:JAVA] = File.join(env_sh[:JAVA_HOME], 'bin', 'java')
  env_sh[:YARN_HEAPSIZE] = '-Xmx1000m'
  env_sh[:JAVA_HEAP_MAX] = env_sh[:YARN_HEAPSIZE]
  env_sh[:YARN_LOGFILE] = 'yarn.log'
  env_sh[:YARN_POLICYFILE] =  'hadoop-policy.xml'

  env_sh[:YARN_OPTS] =
    "-Dhadoop.log.dir=#{env_sh[:YARN_LOG_DIR].shellescape} " +
    "-Dyarn.log.dir=#{env_sh[:YARN_LOG_DIR].shellescape} " +
    "-Dhadoop.log.file=#{env_sh[:YARN_LOGFILE].shellescape} " +
    "-Dyarn.log.dir=#{env_sh[:YARN_LOGFILE].shellescape} " +
    "-Dyarn.id.str=#{env_sh[:YARN_IDENT_STRING].shellescape} " +
    '-Dhadoop.root.logger=INFO,CONSOLE ' +
    '-Dyarn.root.logger=INFO,CONSOLE ' +
    "-Dyarn.policy.file=#{env_sh[:YARN_POLICYFILE].shellescape} " +
    "-Djute.maxbuffer=#{node[:bcpc][:hadoop][:jute][:maxbuffer]}"

  env_sh[:YARN_NODEMANAGER_OPTS] =
    '-Dcom.sun.management.jmxremote.ssl=false ' +
    '-Dcom.sun.management.jmxremote.authenticate=false ' +
    '-Dcom.sun.management.jmxremote.port=' +
    node[:bcpc][:hadoop][:nodemanager][:jmx][:port].to_s

  env_sh[:YARN_NODEMANAGER_OPTS] =
    '-Dcom.sun.management.jmxremote.ssl=false ' +
    '-Dcom.sun.management.jmxremote.authenticate=false ' +
    '-Dcom.sun.management.jmxremote.port=' +
    node[:bcpc][:hadoop][:resourcemanager][:jmx][:port].to_s
end

default[:bcpc][:hadoop][:yarn][:site_xml].tap do |site_xml|
  site_xml['yarn.resourcemanager.ha.enabled'] = nil
end

default["bcpc"]["hadoop"]["yarn"]["log-aggregation_retain-seconds"] = 60*60*24*31
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_memory"]["ratio"] = 0.5
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_memory"]["size"] = nil
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_vcpu"]["ratio"] = 0.5
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["avail_vcpu"]["count"] = nil
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["port"] = 45454
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["class"] = "org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["minimum-allocation-mb"] = 256
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["fair"]["preemption"] = true
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["fair"]["min-vcores"] = 2
default['bcpc']['hadoop']['yarn']['historyserver']['heap']["size"] = 128
default['bcpc']['hadoop']['yarn']['historyserver']['heap']["ratio"] = 0
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["port"] = 8032
default['bcpc']['hadoop']['yarn']['aux_services']['mapreduce_shuffle']['class'] = 'org.apache.hadoop.mapred.ShuffleHandler'
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["yarn.client.failover-sleep-base-ms"] = 150
default['bcpc']['hadoop']['yarn']['nodemanager']['vmem-check-enabled'] = false
default['bcpc']['hadoop']['yarn']['timeline-service']['client']['max-retries'] = 0
default["bcpc"]["hadoop"]["yarn"]["fairsharepreemptiontimeout"] = 150
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["maximum-applications"] = 10000
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["maximum-am-resource-percent"] = 0.1
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["resource-calculator"] = "org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["root"]["queues"] = "default"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["root"]["default"]["capacity"] = 100
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["root"]["default"]["user-limit-factor"] = 1
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["root"]["default"]["maximum-capacity"] = 100
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["root"]["default"]["state"] = "RUNNING"
default["bcpc"]["hadoop"]["yarn"]["yarn"]["scheduler"]["capacity"]["root"]["default"]["acl_submit_applications"] = "*"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["root"]["default"]["acl_administer_queue"] = "*"
default["bcpc"]["hadoop"]["yarn"]["scheduler"]["capacity"]["node-locality-delay"] = -1
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["recovery"]["enabled"] = true
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["store"]["class"] = "org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore"
default["bcpc"]["hadoop"]["yarn"]["log-aggregation-enable"] = true
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["log-aggregation"]["roll-monitoring-interval-seconds"] = 1800
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["log-aggregation"]["compression-type"] = "gz"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["container-executor"]["class"] = "org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor"
default["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["nodes"]["exclude-path"] = "/etc/hadoop/conf/yarn.exclude"
default["bcpc"]["hadoop"]["yarn.nodemanager.linux-container-executor.group"] = "yarn"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["linux-container-executor"]["nonsecure-mode"]["limit-users"] = false
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["linux-container-executor"]["resources-handler"]["class"] = "org.apache.hadoop.yarn.server.nodemanager.util.CgroupsLCEResourcesHandler"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["linux-container-executor"]["cgroups"]["mount-path"] = "/sys/fs/cgroup/"
default["bcpc"]["hadoop"]["yarn"]["nodemanager"]["remote-app-log-dir"] = "/var/log/hadoop-yarn/apps"
default["bcpc"]["hadoop"]["yarn"]["client"]["failover-proxy-provider"] = "org.apache.hadoop.yarn.client.ConfiguredRMFailoverProxyProvider"
