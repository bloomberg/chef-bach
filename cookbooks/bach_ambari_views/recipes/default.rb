# Change default values
# Ambari properties
node.override['ambari-chef']['webhcat.hostname'] = get_nodes_for('hive_server', 'bcpc-hadoop') 
node.override['ambari-chef']['yarn.ats.url'] = 'http://u1202.ambari.apache.org:8188'
node.override['ambari-chef']['oozie.service.uri'] = 'http://u1203.ambari.apache.org:11000/oozie'
node.override['ambari-chef']['yarn.resourcemanager.url'] = 'u1202.ambari.apache.org:8088'
node.override['ambari-chef']['ambari_server_host'] = 'servername.ambari.apache.org'
node.override['ambari-chef']['hive.host'] = get_nodes_for('hive_server', 'bcpc-hadoop')
node.override['ambari-chef']['ambari_views_url'] = 'http://default-ubuntu-1404:8080/api/v1/views'
node.override['ambari-chef']['ambari_database_password'] = secure_password()

get_namenodes.each_with_index do |nn, index|
  node.override['ambari-chef']["webhdfs.ha.namenode.http-address.nn#{index}"] = "#{nn}:50070" 
  node.override['ambari-chef']["webhdfs.ha.namenode.https-address.nn#{index}"] = "#{nn}:50470" 
  node.override['ambari-chef']["webhdfs.ha.namenode.rpc-address.nn#{index}"] = "#{nn}:8020" 
end

node.override['ambari-chef']['webhdfs.ha.namenodes.list'] = \
  (1..get_namenodes.length).map {|nn|"nn#{nn}"}.join(',')
