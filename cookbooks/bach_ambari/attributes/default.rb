node.force_default['ambari']['install_java'] = false
node.force_default['ambari']['java_home'] = "#{node['bcpc']['hadoop']['java']}"


# FILES
namenodes = get_namenodes.select{ |nn| nn[:bcpc][:node_number] }.map{ |nn| "namenode#{nn[:bcpc][:node_number]}" }.join(',')

namenodes_fqdn = get_namenodes.map { |nn| float_host(nn[:fqdn]) }

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

node.force_default['ambari']['proxyuser'] = 'ambari'

if node[:bcpc][:hadoop][:kerberos][:enable]
   node.force_default['ambari']['webhdfs.auth'] = "auth=KERBEROS;proxyuser=ambari"
   node.force_default['ambari']['kerberos']['enabled'] = true
   node.force_default['ambari']['kerberos']['principal'] = "ambari/#{float_host(node[:fqdn])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
end

#Hive jdbc url consturct
hive_jdbc_url = 'jdbc:hive2://'
zookeerpQurom = node['bcpc']['hadoop']['zookeeper']['servers'].map{ |s| float_host(s[:hostname])}.join(',')
zookeeperNamespace = "HS2-#{node.chef_environment}-#{node['bcpc']['hadoop']['hive']['server2']['authentication']}"
hive_jdbc_url += zookeerpQurom
hive_jdbc_url += '/serviceDiscoveryMode=zooKeeper;zooKeeperNamespace='
hive_jdbc_url += zookeeperNamespace


if node['bcpc']['hadoop']['kerberos']['enable'] && node['bcpc']['hadoop']['hive']['server2']['authentication'] == 'KERBEROS'
  hive_principal = ";#{node['bcpc']['hadoop']['kerberos']['data']['hive']['principal']}/_HOST@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  hive_jdbc_url += hive_principal
end

node.force_default['ambari']['hive.jdbc.url'] = "#{hive_jdbc_url}"

resource_manager_url = node[:bcpc][:hadoop][:rm_hosts].map{ |r| 'http://'+float_host(h[:hostname]+':8088')}.join(',')

node.force_default['ambari']['yarn.resourcemanager.url'] = "#{resource_manager_url}"


# Ambari external database attributes
# Ambari External Database attributes
node.force_default['ambari']['db_type'] = 'mysql'

mysql_port = node['bcpc']['hadoop']['mysql_port'] || 3306


node.force_default['ambari']['databaseport'] = "#{mysql_port}"
# node.force_default['ambari']['databasehost'] = mysql_hosts
node.force_default['ambari']['databasename'] = 'ambari'
node.force_default['ambari']['databaseusername'] = 'ambari'
node.force_default['ambari']['databasepassword'] = get_config('mysql-ambari-password') || get_config('password', 'mysql-ambari', 'os')
node.default['ambari']['mysql_schema_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql'
