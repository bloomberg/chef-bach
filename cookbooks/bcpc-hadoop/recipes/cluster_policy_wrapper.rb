set_hosts

zookeeper_quorum = node['bcpc']['hadoop']['zookeeper']['servers'].map do |zks|
  float_host(zks.hostname)
end

node.default['bach_policies']['hbase']['properties'].tap do |hbase|
  hbase['zkQuorum'] = zookeeper_quorum.join(',')
  hbase['nameNode'] = node.chef_environment
  hbase['jobTracker'] = node.chef_environment
  hbase['realm'] = node['bcpc']['hadoop']['kerberos']['realm']
  hbase['oozie.wf.application.path'] = "hdfs://#{hbase['nameNode']}" \
                                       '/bach_policies/hbase'
  # separated by commas
  # namespace_name:user_name,
  hbase['bach.policies.hbase.tenants'] = 'ubuntu:ubuntu'
end

oozie_hosts = node['bcpc']['hadoop']['oozie_hosts']
if defined? oozie_hosts && !oozie_hosts.empty?
  node.default['bach_policies']['oozie_url'] = \
    "http://#{float_host(oozie_hosts.first[:hostname])}:11000/oozie"
end
