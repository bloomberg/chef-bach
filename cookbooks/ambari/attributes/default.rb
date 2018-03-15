
# APT repository attributes
default['apt']['compile_time_update'] = 'true'

default['ambari']['repo_keyserver'] = 'keyserver.ubuntu.com'
default['ambari']['repo_key'] = 'B9733A7A07513CAD'
node.default['ambari']['ambari_server_version'] = '2.6.1.5'
node.default['ambari']['os']['ubuntu_version'] = 14

node.default['ambari']['ambari_ubuntu_repo_url'] = "http://public-repo-1.hortonworks.com/ambari/ubuntu#{node['ambari']['os']['ubuntu_version']}/2.x/updates/#{node['ambari']['ambari_server_version']}"

# Ambari properties
node.default['ambari']['ambari-server-startup-web-timeout'] = '150'
node.default['ambari']['ambari_server_host'] = 'servername.ambari.apache.org'
node.default['ambari']['ambari_server_conf_dir'] = '/etc/ambari-server/conf/'
node.default['ambari']['ambari_agent_conf_dir'] = '/etc/ambari-ag/ent/conf/'


# node.default['ambari']['java_home'] = "/usr/lib/jvm/java-#{node[:java][:jdk_version]}-#{node[:java][:install_flavor]}-amd64"
node.default['ambari']['java_home'] = "/usr/lib/jvm/java-8-oracle-amd64"

node.default['ambari']['use_local_repo'] = 'false'
node.default['ambari']['ambari_server_base_url'] = 'http://localhost:8080'
node.default['ambari']['ambari_views_url'] = "#{node['ambari']['ambari_server_base_url']}/api/v1/views"

node.default['ambari']['proxyuser'] = 'ambari'

node.default['ambari']['admin']['user'] = 'admin'
node.default['ambari']['admin']['password'] = 'admin'

node.default['ambari']['kerberos']['enabled'] = false
node.default['ambari']['kerberos']['principal'] = 'ambari@EXAMPLE.COM'
node.default['ambari']['kerberos']['keytab']['location'] = '/etc/security/keytabs/ambari.service.keytab'

#Ambari internal postgres database attributes
node.default['ambari']['pg_db_script_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-Postgres-EMBEDDED-CREATE.sql'
node.default['ambari']['pg_schema_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql'

# Ambari External Database attributes
node.default['ambari']['embeddeddbhost'] = 'localhost'
node.default['ambari']['db_type'] = 'embedded'
node.default['ambari']['databaseport'] = '3306'
node.default['ambari']['databasehost'] = ['localhost']
node.default['ambari']['databasename'] = 'ambari'
node.default['ambari']['databaseusername'] = 'ambari'
node.default['ambari']['databasepassword'] = 'bigdata'


# FILES view attributes
node.default['ambari']['files_path'] = "FILES/versions/1.0.0/instances/FILES_NEW_INSTANCE"
node.default['ambari']['webhdfs.client.failover.proxy.provider'] = 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
node.default['ambari']['webhdfs.ha.namenode.http-address.nn1'] = 'namenode1:50070'
node.default['ambari']['webhdfs.ha.namenode.http-address.nn2'] = 'namenode2:50070'
node.default['ambari']['webhdfs.ha.namenode.https-address.nn1'] = 'namenode1:50470'
node.default['ambari']['webhdfs.ha.namenode.https-address.nn2'] = 'namenode2:50470'
node.default['ambari']['webhdfs.ha.namenode.rpc-address.nn1'] = 'namenode1:8020'
node.default['ambari']['webhdfs.ha.namenode.rpc-address.nn2'] = 'namenode2:8020'
node.default['ambari']['webhdfs.ha.namenodes.list'] = 'nn1,nn2'
node.default['ambari']['webhdfs.nameservices'] = 'hacluster'
node.default['ambari']['webhdfs.url'] = 'webhdfs://hacluster'
node.default['ambari']['webhdfs.auth'] = 'auth=SIMPLE'


# Hive View Attributes
node.default['ambari']['hive20_view_path'] = 'HIVE/versions/2.0.0/instances/HIVE_NEW_INSTANCE'
node.default['ambari']['hive.jdbc.url'] = 'jdbc:hive2://127.0.0.1:10000'
node.default['ambari']['yarn.ats.url'] = 'http://localhost:8188'
node.default['ambari']['yarn.resourcemanager.url'] = 'http://localhost:8088'
node.default['ambari']['hive20_proxy_user'] = 'hive.server2.proxy.user=${username}'

#WorkflowManager_view Attributes
node.default['ambari']['oozie.service.uri'] = 'http://localhost:11000/oozie'
node.default['ambari']['hadoop.security.authentication'] = 'simple'
node.default['ambari']['wfmanager_view_path'] = 'WORKFLOW_MANAGER/versions/1.0.0/instances/WFM_NEW_INSTANCE'
node.default['ambari']['yarn.resourcemanager.address'] = 'http://localhost:8032'

#Tez views
node.default['ambari']['tez_view_path'] = 'TEZ/versions/0.7.0.2.6.4.0-91/instances/TEZ_NEW_INSTANCE'
node.default['ambari']['timeline.http.auth.type'] = 'simple'
node.default['ambari']['hadoop.http.auth.type'] = 'simple'


# Ambari Views Attributes
node.default['ambari']['webhcat.hostname'] = 'u1203.ambari.apache.org'
node.default['ambari']['webhcat.port'] = '50111'
node.default['ambari']['webhcat.hostname'] = 'u1203.ambari.apache.org'
node.default['ambari']['webhcat.port'] = '50111'
