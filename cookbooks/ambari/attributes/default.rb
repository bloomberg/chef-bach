#
# Cookbook :: ambari
# Attribute :: default
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

# APT repository attributes
default['apt']['compile_time_update'] = 'true'

default['ambari']['repo_key'] = 'hortonworks.key'#'B9733A7A07513CAD'
default['ambari']['ambari_server_version'] = '2.6.1.5'
default['ambari']['platform_major_version'] = "#{node['platform']}#{node['platform_version'].split('.')[0]}"
default['ambari']['ambari_ubuntu_repo_url'] = "http://public-repo-1.hortonworks.com/ambari/#{node['ambari']['platform_major_version']}/2.x/updates/#{node['ambari']['ambari_server_version']}"

# Ambari properties
default['ambari']['ambari-server-startup-web-timeout'] = '150'
default['ambari']['ambari_server_host'] = 'servername.ambari.apache.org'
default['ambari']['ambari_server_conf_dir'] = '/etc/ambari-server/conf/'
default['ambari']['ambari_agent_conf_dir'] = '/etc/ambari-ag/ent/conf/'


# default['ambari']['java_home'] = "/usr/lib/jvm/java-#{node[:java][:jdk_version]}-#{node[:java][:install_flavor]}-amd64"
default['ambari']['java_home'] = "/usr/lib/jvm/java-8-oracle-amd64"

default['ambari']['use_local_repo'] = 'false'
default['ambari']['ambari_server_base_url'] = 'http://localhost:8080'
default['ambari']['ambari_views_url'] = "#{node['ambari']['ambari_server_base_url']}/api/v1/views"


default['ambari']['admin']['user'] = 'admin'
default['ambari']['admin']['password'] = 'password'
default['ambari']['admin']['default_password'] = 'admin'

default['ambari']['kerberos']['enabled'] = false
default['ambari']['kerberos']['principal'] = 'ambari@EXAMPLE.COM'
default['ambari']['kerberos']['keytab']['location'] = '/etc/security/keytabs/ambari.service.keytab'

#Ambari internal postgres database attributes
default['ambari']['pg_db_script_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-Postgres-EMBEDDED-CREATE.sql'
default['ambari']['pg_schema_path'] = '/var/lib/ambari-server/resources/Ambari-DDL-Postgres-CREATE.sql'

# Ambari External Database attributes
default['ambari']['embeddeddbhost'] = 'localhost'
default['ambari']['db_type'] = 'embedded'
default['ambari']['databaseport'] = '3306'
default['ambari']['databasehost'] = ['localhost']
default['ambari']['databasename'] = 'ambari'
default['ambari']['databaseusername'] = 'ambari'
default['ambari']['databasepassword'] = 'bigdata'


# FILES view attributes
default['ambari']['files_path'] = "FILES/versions/1.0.0/instances/FILES_NEW_INSTANCE"
default['ambari']['webhdfs.client.failover.proxy.provider'] = 'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'
default['ambari']['webhdfs.ha.namenode.http-address.nn1'] = 'namenode1:50070'
default['ambari']['webhdfs.ha.namenode.http-address.nn2'] = 'namenode2:50070'
default['ambari']['webhdfs.ha.namenode.https-address.nn1'] = 'namenode1:50470'
default['ambari']['webhdfs.ha.namenode.https-address.nn2'] = 'namenode2:50470'
default['ambari']['webhdfs.ha.namenode.rpc-address.nn1'] = 'namenode1:8020'
default['ambari']['webhdfs.ha.namenode.rpc-address.nn2'] = 'namenode2:8020'
default['ambari']['webhdfs.ha.namenodes.list'] = 'nn1,nn2'
default['ambari']['webhdfs.nameservices'] = 'hacluster'
default['ambari']['webhdfs.url'] = 'webhdfs://hacluster'
default['ambari']['webhdfs.auth'] = 'auth=SIMPLE'


# Hive View Attributes
default['ambari']['hive20_view_path'] = 'HIVE/versions/2.0.0/instances/HIVE_NEW_INSTANCE'
default['ambari']['hive.jdbc.url'] = 'jdbc:hive2://127.0.0.1:10000'
default['ambari']['yarn.ats.url'] = 'http://localhost:8188'
default['ambari']['yarn.resourcemanager.url'] = 'http://localhost:8088'
default['ambari']['hive20_proxy_user'] = 'hive.server2.proxy.user=${username}'

#WorkflowManager_view Attributes
default['ambari']['oozie.service.uri'] = 'http://localhost:11000/oozie'
default['ambari']['hadoop.security.authentication'] = 'simple'
default['ambari']['wfmanager_view_path'] = 'WORKFLOW_MANAGER/versions/1.0.0/instances/WFM_NEW_INSTANCE'
default['ambari']['yarn.resourcemanager.address'] = 'http://localhost:8032'

#Tez views
default['ambari']['tez_view_path'] = 'TEZ/versions/0.7.0.2.6.4.0-91/instances/TEZ_NEW_INSTANCE'
default['ambari']['timeline.http.auth.type'] = 'simple'
default['ambari']['hadoop.http.auth.type'] = 'simple'


# Ambari Views Attributes
default['ambari']['webhcat.hostname'] = 'u1203.ambari.apache.org'
default['ambari']['webhcat.port'] = '50111'
default['ambari']['webhcat.hostname'] = 'u1203.ambari.apache.org'
default['ambari']['webhcat.port'] = '50111'

# Ambari LDAP Sync attributes
default['ambari']['ldap']['groups_to_sync']=''
default['ambari']['ldap']['groups_file']='ldap-groups.txt'
default['ambari']['ldap']['password_file']='ldap-password.dat'
default['ambari']['ambari.ldap.isConfigured']=false
default['ambari']['client.security']='ldap'
default['ambari']['ldap.sync.username.collision.behavior']='convert'

default['ambari']['authentication']['ldap'].tap do |ldap|
  ldap['baseDn']='DC=bcpc,DC=example,DC=com'
  ldap['bindAnonymously']=false
  ldap['dnAttribute']='distinguishedName'
  ldap['groupMembershipAttr']='member'
  ldap['groupNamingAttr']='cn'
  ldap['groupObjectClass']='group'
  ldap['managerDn']=''
  ldap['managerPassword']=File.join(node['ambari']['ambari_server_conf_dir'],node['ambari']['ldap']['password_file'])
  ldap['primaryUrl']=''
  ldap['secondaryUrl']=''
  ldap['useSSL']=false
  ldap['userObjectClass']='user'
  ldap['usernameAttribute']='sAMAccountName'
end
