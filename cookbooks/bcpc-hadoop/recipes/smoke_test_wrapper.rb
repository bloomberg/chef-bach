# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# Cookbook Name:: bcpc-hadoop
# Recipe:: smoke_test_wrapper
#
# Copyright 2016, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'base64'

krb_realm = node[:bcpc][:hadoop][:kerberos][:realm]
test_user = node['hadoop_smoke_tests']['oozie_user']
hbase_ns = node['hadoop_smoke_tests']['hbase_ns']
tester_princ = "#{test_user}@#{krb_realm}"
tester_keytab = get_config('keytab', 'test_user_keytab', 'os')

include_recipe 'bcpc-hadoop::smoke_test_user'

chef_env = node.environment
resource_managers = node[:bcpc][:hadoop][:rm_hosts].map do |rms|
  float_host(rms.hostname)
end
zookeeper_quorum = node[:bcpc][:hadoop][:zookeeper][:servers].map do |zks|
  float_host(zks.hostname)
end
fs = "hdfs://#{chef_env}"
rm = resource_managers.length > 1 ? chef_env : resource_managers[0]
thrift_uris = node[:bcpc][:hadoop][:hive_hosts]
              .map { |s| 'thrift://' + float_host(s[:hostname]) + ':9083' }
              .join(',')
node.default['hadoop_smoke_tests']['carbon-line-receiver'] = node[:bcpc][:graphite][:ip]
node.default['hadoop_smoke_tests']['carbon-line-port'] = node[:bcpc][:graphite][:relay_port]
node.default['hadoop_smoke_tests']['oozie_hosts'] = node[:bcpc][:hadoop][:oozie_hosts]
                                                    .map do |entry|
  float_host(entry['hostname'])
end
node.default['hadoop_smoke_tests']['wf_path'] = 'hdfs://Test-Laptop/user/'\
"#{test_user}/oozie-smoke-tests/wf"
node.default['hadoop_smoke_tests']['wf']['co_path'] = 'hdfs://Test-Laptop/user/'\
"#{test_user}/oozie-smoke-tests/co"
node.default['hadoop_smoke_tests']['wf']['rm'] = rm
node.default['hadoop_smoke_tests']['wf']['fs'] = fs
node.default['hadoop_smoke_tests']['wf']['thrift_uris'] = thrift_uris
node.default['hadoop_smoke_tests']['wf']['krb_realm'] = krb_realm
node.default['hadoop_smoke_tests']['wf']['zk_quorum'] = zookeeper_quorum.join(',')
node.default['hadoop_smoke_tests']['wf']['hbase_master_princ'] = "hbase/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hbase_region_princ'] = "hbase/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hive_hmeta_princ'] = "hive/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hive_hserver_princ'] = "hive/_HOST@#{krb_realm}"

# create hbase namespace for tester
bash "HBASE namespace for smoke tests #{hbase_ns}" do
  code <<-EOH
  echo "create_namespace '#{hbase_ns}'" | hbase shell
  EOH
  user 'hbase'
  not_if "hbase shell <<< 'list_namespace' | grep '#{hbase_ns}'", user: 'hbase'
end

# Permissions test user to access HBase and get DTs
bash "HBASE permission for #{test_user}" do
  code <<-EOH
  echo "grant '#{test_user}', 'RWCAX', @#{hbase_ns}" | hbase shell
  EOH
  user 'hbase'
end

# init test_user credentials
file "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/smoke_test.keytab" do
  content Base64.decode64(tester_keytab)
  user test_user
  group 'root'
  mode 0o0600
end

execute "kinit #{tester_princ} credentials" do
  command "kinit -kt #{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}"\
  "/smoke_test.keytab #{tester_princ}"
  user test_user
end

hive_jdbc_url = 'jdbc:hive2://'
zookeeper_quorum_port = node[:bcpc][:hadoop][:zookeeper][:servers].map do |s|
  float_host(s[:hostname]) + ":#{node[:bcpc][:hadoop][:zookeeper][:port]}"
end
zookeeper_namespace = "HS2-#{node.chef_environment}-"\
"#{node['bcpc']['hadoop']['hive']['server2']['authentication']}"

hive_jdbc_url += zookeeper_quorum_port.join(',')
hive_jdbc_url += '/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace='
hive_jdbc_url += zookeeper_namespace

chef_env = node.environment
resource_managers = node[:bcpc][:hadoop][:rm_hosts].map do |rms|
  float_host(rms.hostname)
end
zookeeper_quorum = node[:bcpc][:hadoop][:zookeeper][:servers].map do |zks|
  float_host(zks.hostname)
end
fs = "hdfs://#{chef_env}"
rm = resource_managers.length > 1 ? chef_env : resource_managers[0]
thrift_uris = node[:bcpc][:hadoop][:hive_hosts]
              .map { |s| 'thrift://' + float_host(s[:hostname]) + ':9083' }
              .join(',')
node.default['hadoop_smoke_tests']['carbon-line-receiver'] = node[:bcpc][:graphite][:ip]
node.default['hadoop_smoke_tests']['carbon-line-port'] = node[:bcpc][:graphite][:relay_port]
node.default['hadoop_smoke_tests']['oozie_hosts'] = node[:bcpc][:hadoop][:oozie_hosts]
                                                    .map do |entry|
                                                      float_host(entry['hostname'])
                                                    end
node.default['hadoop_smoke_tests']['wf_path'] = 'hdfs://Test-Laptop/user/'\
"#{test_user}/oozie-smoke-tests/wf"
node.default['hadoop_smoke_tests']['wf']['co_path'] = 'hdfs://Test-Laptop/user/'\
"#{test_user}/oozie-smoke-tests/co"
node.default['hadoop_smoke_tests']['wf']['rm'] = rm
node.default['hadoop_smoke_tests']['wf']['fs'] = fs
node.default['hadoop_smoke_tests']['wf']['thrift_uris'] = thrift_uris
node.default['hadoop_smoke_tests']['wf']['krb_realm'] = krb_realm
node.default['hadoop_smoke_tests']['wf']['zk_quorum'] = zookeeper_quorum.join(',')
node.default['hadoop_smoke_tests']['wf']['hbase_master_princ'] = "hbase/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hbase_region_princ'] = "hbase/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hive_hmeta_princ'] = "hive/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hive_hserver_princ'] = "hive/_HOST@#{krb_realm}"
node.default['hadoop_smoke_tests']['wf']['hive_jdbc_url'] = hive_jdbc_url

include_recipe 'smoke-tests::oozie_smoke_test'
