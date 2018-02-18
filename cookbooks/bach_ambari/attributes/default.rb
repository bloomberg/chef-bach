# system attributes


# APT repository attributes
default['apt']['compile_time_update'] = 'true'

node.default['bach_ambari']['ambari_server_version'] = '2.6.1'

case node.default['bach_ambari']['ambari_server_version']
when '2.6.1'
  node.default['bach_ambari']['ambari_repo_ubuntu_14'] = 'http://public-repo-1.hortonworks.com/ambari/ubuntu14/2.x/updates/2.6.1.0'
  node.default['bach_ambari']['ambari_repo_ubuntu_16'] = 'http://public-repo-1.hortonworks.com/ambari/ubuntu16/2.x/updates/2.6.1.0'
else
  raise "Ambari Server #{node['bach_ambari']['ambari_server_version']} is not supported"
end
# Ambari properties
node.default['bach_ambari']['ambari-server-startup-web-timeout'] = '150'
node.default['bach_ambari']['ambari_server_host'] = 'servername.ambari.apache.org'
node.default['bach_ambari']['ambari_server_conf_dir'] = '/etc/ambari-server/conf/'
node.default['bach_ambari']['ambari_agent_conf_dir'] = '/etc/ambari-agent/conf/'
node.default['bach_ambari']['ambari_database_password'] = 'bigdata'


# node.default['bach_ambari']['java_home'] = "/usr/lib/jvm/java-#{node[:java][:jdk_version]}-#{node[:java][:install_flavor]}-amd64"
node.default['bach_ambari']['java_home'] = 'embedded'

node.default['bach_ambari']['use_local_repo'] = 'false'

node.default['bach_ambari']['ambari_views_url'] = 'http://localhost:8080/api/v1/views'

node.default['bach_ambari']['admin']['user'] = 'admin'
node.default['bach_ambari']['admin']['password'] = 'admin'

node.default['bach_ambari']['kerberos']['enabled'] = false
node.default['bach_ambari']['kerberos']['principal'] = 'ambari@EXAMPLE.COM'
node.default['bach_ambari']['kerberos']['keytab']['location'] = '/etc/security/keytabs/ambari.service.keytab'


# Ambari External Database attributes
node.default['bach_ambari']['embeddeddbhost'] = 'localhost'
node.default['bach_ambari']['db_type'] = 'embedded'
node.default['bach_ambari']['databaseport'] = '3306'
node.default['bach_ambari']['databasehost'] = ['localhost']
# node.default['bach_ambari']['databasehost'] = '10.0.100.11'
node.default['bach_ambari']['databasename'] = 'ambari'
node.default['bach_ambari']['databaseusername'] = 'ambari'
node.default['bach_ambari']['databasepassword'] = 'bigdata'



# FILES view attributes
node.default['bach_ambari']['webhdfs.client.failover.proxy.provider'] = 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
node.default['bach_ambari']['webhdfs.ha.namenode.http-address.nn1'] = 'namenode1:50070'
node.default['bach_ambari']['webhdfs.ha.namenode.http-address.nn2'] = 'namenode2:50070'
node.default['bach_ambari']['webhdfs.ha.namenode.https-address.nn1'] = 'namenode1:50470'
node.default['bach_ambari']['webhdfs.ha.namenode.https-address.nn2'] = 'namenode2:50470'
node.default['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1'] = 'namenode1:8020'
node.default['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2'] = 'namenode2:8020'
node.default['bach_ambari']['webhdfs.ha.namenodes.list'] = 'nn1,nn2'
node.default['bach_ambari']['webhdfs.nameservices'] = 'hacluster'
node.default['bach_ambari']['webhdfs.url'] = 'webhdfs://hacluster'
node.default['bach_ambari']['webhdfs.auth'] = 'auth=SIMPLE'


node.default['bach_ambari']['hive.host'] =  'u1203.ambari.apache.org'
node.default['bach_ambari']['hive.http.path'] = 'cliservice'
node.default['bach_ambari']['hive.http.port'] = '10001'
node.default['bach_ambari']['hive.metastore.warehouse.dir'] = '/apps/hive/warehouse'
node.default['bach_ambari']['hive.port'] = '10000'
node.default['bach_ambari']['hive.transport.mode'] = 'binary'
node.default['bach_ambari']['yarn.ats.url'] = 'http://u1202.ambari.apache.org:8188'
node.default['bach_ambari']['yarn.resourcemanager.url'] = 'u1202.ambari.apache.org:8088'
node.default['bach_ambari']['webhcat.hostname'] = 'u1203.ambari.apache.org'
node.default['bach_ambari']['webhcat.port'] = '50111'
node.default['bach_ambari']['oozie.service.uri'] = 'http://u1203.ambari.apache.org:11000/oozie'
node.default['bach_ambari']['hadoop.security.authentication'] = 'simple'
node.default['bach_ambari']['webhcat.hostname'] = 'u1203.ambari.apache.org'
node.default['bach_ambari']['webhcat.port'] = '50111'
