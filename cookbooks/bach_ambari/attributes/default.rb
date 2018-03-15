#
# Cookbook :: bach_ambari
# Attributes :: default
# Copyright 2018, Bloomberg Finance L.P.
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

node.force_default['ambari']['install_java'] = false
node.force_default['ambari']['java_home'] = "#{node['bcpc']['hadoop']['java']}"

namenodes_cach = get_namenodes
# FILES
namenodes = namenodes_cach.select{ |nn| nn[:bcpc][:node_number] }.map{ |nn| "namenode#{nn[:bcpc][:node_number]}" }.join(',')

namenodes_fqdn = namenodes_cach.map { |nn| float_host(nn[:fqdn]) }

node.force_default['ambari']['webhdfs.ha.namenode.http-address.nn1'] = "#{namenodes_fqdn[0]}:#{node['bcpc']['hadoop']['namenode']['http']['port']}"
node.force_default['ambari']['webhdfs.ha.namenode.https-address.nn1'] = "#{namenodes_fqdn[0]}:#{node['bcpc']['hadoop']['namenode']['https']['port']}"
node.force_default['ambari']['webhdfs.ha.namenode.rpc-address.nn1'] = "#{namenodes_fqdn[0]}:#{node['bcpc']['hadoop']['namenode']['rpc']['port']}"

if node[:bcpc][:hadoop][:hdfs][:HA]
   node.force_default['ambari']['webhdfs.ha.namenode.http-address.nn2'] = "#{namenodes_fqdn[1]}:#{node['bcpc']['hadoop']['namenode']['http']['port']}"
   node.force_default['ambari']['webhdfs.ha.namenode.https-address.nn2'] = "#{namenodes_fqdn[1]}:#{node['bcpc']['hadoop']['namenode']['https']['port']}"
   node.force_default['ambari']['webhdfs.ha.namenode.rpc-address.nn2'] = "#{namenodes_fqdn[1]}:#{node['bcpc']['hadoop']['namenode']['rpc']['port']}"
end

node.force_default['ambari']['webhdfs.ha.namenodes.list'] = "#{namenodes}"
node.force_default['ambari']['webhdfs.nameservices'] = node.chef_environment
node.force_default['ambari']['webhdfs.url'] = "webhdfs://#{node.chef_environment}"

ambari_proxy_user = "#{node['bcpc']['hadoop']['proxyuser']['ambari']}"

if node[:bcpc][:hadoop][:kerberos][:enable]
   node.force_default['ambari']['webhdfs.auth'] = "auth=KERBEROS;proxyuser=#{ambari_proxy_user}"
   node.force_default['ambari']['kerberos']['enabled'] = true
   node.force_default['ambari']['kerberos']['principal'] = "#{ambari_proxy_user}/#{float_host(node[:fqdn])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
   node.force_default['ambari']['hadoop.security.authentication'] = 'kerberos'
   node.force_default['ambari']['timeline.http.auth.type'] = 'kerberos'
   node.force_default['ambari']['hadoop.http.auth.type'] = 'kerberos'
end

set_hosts
#Hive jdbc url consturct
hive_jdbc_url = 'jdbc:hive2://'
zookeerpQurom = node['bcpc']['hadoop']['zookeeper']['servers'].map{ |s| float_host(s[:hostname])+":#{node[:bcpc][:hadoop][:zookeeper][:port]}" }.join(',')
zookeeperNamespace = "HS2-#{node.chef_environment}-#{node['bcpc']['hadoop']['hive']['server2']['authentication']}"
hive_jdbc_url += zookeerpQurom
hive_jdbc_url += '/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace='
hive_jdbc_url += zookeeperNamespace

if node['bcpc']['hadoop']['kerberos']['enable'] && node['bcpc']['hadoop']['hive']['server2']['authentication'] == 'KERBEROS'
  hive_principal = ";#{node['bcpc']['hadoop']['kerberos']['data']['hive']['principal']}/_HOST@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  hive_jdbc_url += hive_principal
end


node.force_default['ambari']['hive.jdbc.url'] = "#{hive_jdbc_url}"
ts_port = node['bcpc']['hadoop']['yarn']['timeline_server']['webapp']['port']
rm_port = node['bcpc']['hadoop']['yarn']['resourcemanager']['webapp']['port']

resource_manager_url = node[:bcpc][:hadoop][:rm_hosts].map{ |r| 'http://'+float_host(r[:hostname]+":#{rm_port}")}.join(',')

node.force_default['ambari']['yarn.resourcemanager.url'] = "#{resource_manager_url}"

timeline_server = get_timeline_servers.map { |e| "http://"+ float_host(e[:hostname])+ ":#{ts_port}" }.first

node.force_default['ambari']['yarn.ats.url'] = "#{timeline_server}"

oozie_port = node['bcpc']['hadoop']['oozie_port']

oozie_hosts = node.default['bcpc']['hadoop']['oozie_hosts']

oozie_url = oozie_hosts.map { |e| 'http://'+float_host(e['hostname'])+":#{oozie_port}"  }.first

if oozie_hosts.length >= 2
  oozie_url = oozie_hosts.map { |e| 'http://'+"#{node['bcpc']['management']['vip']}"+":#{oozie_port}" }.first
end

rm_nport = node["bcpc"]["hadoop"]["yarn"]["resourcemanager"]["port"]
rm_address = node[:bcpc][:hadoop][:rm_hosts].map{ |r| 'http://'+float_host(r[:hostname]+":#{rm_nport}")}.join(',')
node.default['ambari']['oozie.service.uri'] = "#{oozie_url}/oozie"
node.default['ambari']['yarn.resourcemanager.address'] = "#{rm_address}"

# Ambari External Database attributes
node.force_default['ambari']['db_type'] = 'mysql'

mysql_port = node['bcpc']['hadoop']['mysql_port'] || 3306

node.force_default['ambari']['databaseport'] = "#{mysql_port}"
# node.force_default['ambari']['databasehost'] = mysql_hosts
node.force_default['ambari']['databasename'] = 'ambari'
node.force_default['ambari']['databaseusername'] = 'ambari'
node.force_default['ambari']['databasepassword'] = get_config('mysql-ambari-password') || get_config('password', 'mysql-ambari', 'os')
node.default['ambari']['mysql_schema_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql'
