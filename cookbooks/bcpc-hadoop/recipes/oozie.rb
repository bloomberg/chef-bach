#
# Cookbook Name:: bcpc-hadoop
# Recipe:: oozie
#
# Copyright 2013, Bloomberg Finance L.P.
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

#
# This recipe configures the Oozie server on head nodes.
#

include_recipe 'bcpc::mysql'
include_recipe 'bcpc-hadoop::oozie_config'

::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

#
# These data bags and vault items are pre-populated at compile time by
# the bcpc::mysql_data_bags recipe.
#
oozie_user = get_config('mysql-oozie-user') || 'oozie'
oozie_password = get_config!('password', 'mysql-oozie', 'os')

hdp_rel = node[:bcpc][:hadoop][:distribution][:active_release]
oozie_conf_dir = "/etc/oozie/conf.#{node.chef_environment}"

include_recipe 'bcpc-hadoop::mysql_connector'

[
  'zip',
  'unzip',
  'extjs',
  'hadooplzo',
  'hadooplzo-native',
  hwx_pkg_str('oozie-server', hdp_rel),
  hwx_pkg_str('oozie-client', hdp_rel),
].flatten.each do |pkg|
  package pkg do
    action :upgrade
  end
end

['oozie-server', 'oozie-client'].each do |pkg|
  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

configure_kerberos 'oozie_spnego' do
  service_name 'spnego'
end

configure_kerberos 'oozie_kerb' do
  service_name 'oozie'
end

OOZIE_LIB_PATH =
  "/usr/hdp/#{hdp_rel}/oozie".freeze

OOZIE_CLIENT_PATH =
  '/usr/hdp/current/oozie-client'.freeze

OOZIE_SERVER_PATH =
  "/usr/hdp/#{hdp_rel}/oozie/oozie-server".freeze

OOZIE_SHARELIB_TARBALL_PATH =
  "/usr/hdp/#{hdp_rel}/oozie/oozie-sharelib.tar.gz".freeze

HDFS_URL = node[:bcpc][:hadoop][:hdfs_url]

directory "#{OOZIE_LIB_PATH}/libext" do
  owner 'oozie'
  group 'oozie'
  mode 00755
  action :create
  recursive true
end

directory '/var/run/oozie' do
  owner 'oozie'
  group 'oozie'
  mode 00755
  action :create
  recursive true
end

[
  '/usr/share/HDP-oozie/ext-2.2.zip',
  '/usr/share/java/mysql-connector-java.jar',
  "/usr/hdp/#{hdp_rel}/hadoop/lib/hadoop-lzo-0.6.0.#{hdp_rel}.jar"
].each do |dst|
  link "#{OOZIE_LIB_PATH}/libext/#{File.basename(dst)}" do
    to dst
  end
end

if not (node.run_list.expand(node.chef_environment).recipes
  .include?('bcpc-hadoop::hbase_master')) then
  package 'hbase' do
    action :upgrade
  end
end

if not (node.run_list.expand(node.chef_environment).recipes
  .include?('bcpc-hadoop::hbase_master')) then
  package 'hbase' do
    action :upgrade
  end
end

HBASE_CLIENT_LIB = "/usr/hdp/#{hdp_rel}/hbase/lib"
(["hbase-common.jar", "hbase-client.jar", "hbase-server.jar",
 "hbase-protocol.jar", "hbase-hadoop2-compat.jar"].map do |flname|
   "#{HBASE_CLIENT_LIB}/#{flname}"
  end +
  Dir["/usr/hdp/#{hdp_rel}/hbase/lib/htrace-core-*"] +
  Dir["/usr/hdp/#{hdp_rel}/hbase/lib/netty-*"]).each do |link_candidate|
    link "link_hbase_jar_#{link_candidate}" do
      to link_candidate
      target_file "#{OOZIE_CLIENT_PATH}/libext/#{File.basename(link_candidate)}"
  end
end

bash 'copy ssl configuration' do
  code("cp -r /usr/hdp/#{hdp_rel}/oozie/tomcat-deployment/conf/ssl " \
       '/etc/oozie/conf/')
end

service 'stop oozie for war setup' do
  action :stop
  supports status: true, restart: true, reload: false
  service_name 'oozie'
  only_if do
    !File.exist?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") ||
      File.mtime("#{OOZIE_CLIENT_PATH}/libext/") >
        File.mtime("#{OOZIE_SERVER_PATH}/webapps/oozie.war")
  end
end

bash 'oozie setup war' do
  code "#{OOZIE_CLIENT_PATH}/bin/oozie-setup.sh prepare-war"
  only_if do
    !File.exist?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") ||
      File.mtime("#{OOZIE_CLIENT_PATH}/libext/") >
        File.mtime("#{OOZIE_SERVER_PATH}/webapps/oozie.war")
  end
end

directory "#{oozie_conf_dir}/action-conf" do
  owner 'root'
  group 'root'
  mode 00755
  action :create
  recursive true
end

directory "#{oozie_conf_dir}/action-conf/hive" do
  mode '0755'
end

directory "#{oozie_conf_dir}/hadoop-conf" do
  owner 'root'
  group 'root'
  mode 00755
  action :create
  recursive true
end

link "#{oozie_conf_dir}/action-conf/hive/hive-site.xml" do
  to "/etc/hive/conf.#{node.chef_environment}/hive-site.xml"
end

link "#{oozie_conf_dir}/core-site.xml" do
  to "/etc/hadoop/conf.#{node.chef_environment}/core-site.xml"
end

link "#{oozie_conf_dir}/yarn-site.xml" do
  to "/etc/hadoop/conf.#{node.chef_environment}/yarn-site.xml"
end

bash 'make oozie user dir' do
  code("hdfs dfs -mkdir -p #{HDFS_URL}/user/oozie && " \
       "hdfs dfs -chown -R oozie #{HDFS_URL}/user/oozie")
  user 'hdfs'
  not_if "hdfs dfs -test -d #{HDFS_URL}/user/oozie", user: 'hdfs'
end

bash 'oozie create shared libs' do
  code("#{OOZIE_CLIENT_PATH}/bin/oozie-setup.sh sharelib create " \
       "-fs #{HDFS_URL} -locallib #{OOZIE_SHARELIB_TARBALL_PATH}")
  user 'oozie'
  not_if do
    require 'digest'
    chksum = node[:bcpc][:hadoop][:oozie][:sharelib_checksum]
    !chksum.nil? &&
      Digest::MD5.hexdigest(File.read(OOZIE_SHARELIB_TARBALL_PATH)) == chksum
  end
  only_if ' echo \'test\' | hdfs dfs -put - /tmp/oozie-test && ' \
          'hdfs dfs -rm -skipTrash /tmp/oozie-test', user: 'hdfs'
  notifies :run, 'ruby_block[update sharelib checksum]', :immediately
end

ruby_block 'update sharelib checksum' do
  block do
    require 'digest'
    node.set[:bcpc][:hadoop][:oozie][:sharelib_checksum] =
      Digest::MD5.hexdigest(File.read(OOZIE_SHARELIB_TARBALL_PATH))
  end
  action :nothing
  notifies :run, 'ruby_block[notify sharelib update]', :immediately
end

ruby_block 'notify sharelib update' do
  block do
    node[:bcpc][:hadoop][:oozie_hosts].each do |oozie_host|
      update_oozie_sharelib(float_host(oozie_host[:hostname]))
    end
  end
  action :nothing
end

template "#{oozie_conf_dir}/action-conf/hive.xml" do
  mode 0644
  source 'ooz_action_hive.xml.erb'
end

file "#{OOZIE_CLIENT_PATH}/oozie.sql" do
  owner 'oozie'
  group 'oozie'
end

#
# It is helpful to connect through the cluster VIP for initial
# database configuration so that failures are caught before the schema
# installation fails with a much less obvious error message.
#
mysql_database 'oozie' do
  connection mysql_global_vip_connection_info
  encoding 'UTF8'
  action :create
end

[
  '%',
  'localhost'
].each do |host_name|
  #
  # Connecting to the global VIP for user creation is safe only
  # because the database cookbook providers use 'CREATE USER', which
  # replicates across cluster members.
  #
  # Performing the same operation with 'INSERT' into system tables
  # will fail to replicate!
  #
  mysql_database_user oozie_user do
    connection mysql_global_vip_connection_info
    host host_name
    password oozie_password
    action :create
  end

  mysql_database_user oozie_user do
    connection mysql_global_vip_connection_info
    database_name 'oozie'
    host host_name
    privileges ['ALL PRIVILEGES']
    action :grant
  end
end

execute 'ooziedb-create' do
  user 'oozie'
  cwd '/tmp'
  command "#{OOZIE_LIB_PATH}/bin/ooziedb.sh create " \
    "-sqlfile #{OOZIE_LIB_PATH}/oozie.sql " \
    '-run Validate DB Connection'
end

link '/etc/init.d/oozie' do
  to "/usr/hdp/#{hdp_rel}/oozie/etc/init.d/oozie-server"
  notifies :run, 'bash[kill oozie-oozie]', :immediate
end

bash 'kill oozie-oozie' do
  code 'pkill -u oozie -f oozie'
  action :nothing
  returns [0, 1]
end

service 'generally run oozie' do
  action [:enable, :start]
  service_name 'oozie'
  supports status: true, restart: true, reload: false
  subscribes :restart, 'link[/etc/init.d/oozie]', :immediate
  subscribes :restart, 'template[/etc/oozie/conf/oozie-env.sh]', :delayed
  subscribes :restart, 'template[/etc/oozie/conf/oozie-site.xml]', :delayed
  subscribes :restart, 'template[/etc/hadoop/conf/hdfs-site.xml]', :delayed
  subscribes :restart, 'template[/etc/hadoop/conf/core-site.xml]', :delayed
  subscribes :restart, 'template[/etc/hadoop/conf/mapred-site.xml]', :delayed
  subscribes :restart, 'template[/etc/hadoop/conf/hadoop-env.sh]', :delayed
  subscribes :restart, 'bash[hdp-select oozie-server]', :delayed
end

ruby_block 'check if oozie running' do
  i = 0
  block do
    until oozie_running?(float_host(node[:fqdn]))
      if i < 10
        sleep(0.5)
        i += 1
        Chef::Log.debug('Oozie is down')
      else
        Chef::Application.fatal!(
          'Oozie is reported as down for more than 5 seconds')
        raise
      end
    end
    Chef::Log.debug('Oozie is up')
  end
  not_if { oozie_running?(float_host(node[:fqdn])) }
end
