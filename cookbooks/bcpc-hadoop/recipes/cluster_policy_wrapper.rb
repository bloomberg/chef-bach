include_recipe 'bcpc-hadoop::cluster_policy_user'

# Download keytab
file File.join(node['bcpc']['hadoop']['kerberos']['keytab']['dir'],
               'bach_policy.keytab') do
  content Base64.decode64(get_config('keytab', 'bach_policy_keytab', 'os'))
  user 'bach_policy'
  group 'root'
  mode '0600'
end

policy_principal = "bach_policy@#{node['bcpc']['hadoop']['kerberos']['realm']}"

execute 'bach_policy: kinit keytab' do
  command "kinit -kt #{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}" \
          "/bach_policy.keytab #{policy_principal}"
  user 'bach_policy'
end

set_hosts

zookeeper_quorum = node['bcpc']['hadoop']['zookeeper']['servers'].map do |zks|
  float_host(zks.hostname)
end

# HBase Policies

node.default['bach_policies']['hbase']['properties'].tap do |hbase|
  hbase['zkQuorum'] = zookeeper_quorum.join(',')
  hbase['nameNode'] = "hdfs://#{node.chef_environment}"
  hbase['jobTracker'] = node.chef_environment
  hbase['realm'] = node['bcpc']['hadoop']['kerberos']['realm']
  hbase['oozie.wf.application.path'] = "#{hbase['nameNode']}" \
                                       '/user/bach_policy/hbase'
  # separated by commas
  # namespace_name:user_name,
  hbase['tenants'] = 'ubuntu:ubuntu'
end

oozie_hosts = node['bcpc']['hadoop']['oozie_hosts']
if defined? oozie_hosts && !oozie_hosts.empty?
  node.default['bach_policies']['oozie_url'] = \
    "http://#{float_host(oozie_hosts.first[:hostname])}:11000/oozie"
end
