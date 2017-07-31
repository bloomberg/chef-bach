# Change default values
default['bach_ambari_views']['ambari_username'] = "ambari-server-#{node.chef_environment}"
# Ambari properties
node.override['ambari-chef']['oozie.service.uri'] = 'http://u1203.ambari.apache.org:11000/oozie'
node.override['ambari-chef']['ambari_server_host'] = 'servername.ambari.apache.org'
node.override['ambari-chef']['ambari_views_url'] = 'http://default-ubuntu-1404:8080/api/v1/views'
node.override['ambari-chef']['java_home'] = node['bcpc']['hadoop']['java']
node.override['ambari-chef']['webhdfs.nameservices'] = node.chef_environment
node.override['ambari-chef']['webhdfs.url'] = "webhdfs://#{node.chef_environment}"

# use 'SIMPLE' for non-Kerberos cluster
node.override['ambari-chef']['webhdfs.auth'] = \
  'auth=KERBEROS;proxyuser=#{node['bach_ambari_views']['ambari_username']}
node.override['ambari-chef']['fs.defaultFS'] = node['bcpc']['hadoop']['hdfs_url']
node.override['ambari-chef']['hive.http.path'] = 'cliservice'
node.override['ambari-chef']['hive.http.port'] = '9083'
node.override['ambari-chef']['hive.metastore.warehouse.dir'] = '/user/hive/warehouse'
node.override['ambari-chef']['hive.port'] = node["bcpc"]["hadoop"]["hive"]["server2"]["port"]
node.override['ambari-chef']['webhcat.port'] = node["bcpc"]["hadoop"]["hive"]["server2"]["port"] 
node.override['ambari-chef']['hadoop.security.authentication'] = \
  node[:bcpc][:hadoop][:kerberos][:enable] ? 'KERBEROS' : 'SIMPLE' 
