#
# Cookbook Name:: bach_ambari
# Recipe:: ambari_server_setup
#
# Copyright (c) 2016 Artem Ervits, All Rights Reserved.

package 'ambari-server' do
  action :install
end

# template requires a directory created
config_dir = node['bach_ambari']['ambari_server_conf_dir']

directory config_dir do
  recursive true
end

user 'ambari' do
  comment 'ambari user is created'
end

java_opts = ''

if node['bach_ambari']['java_home'] != 'embedded'
  java_opts += "-j #{node['bach_ambari']['java_home']}"
end
set_hosts




db_opts = ''
mysql_jdbc_url = "jdbc:mysql://"

case node['bach_ambari']['db_type']
when 'mysql'
  mysql_port = node['bach_ambari']['databaseport']
  hostnameport = node['bach_ambari']['databasehost'].map { |m| m.to_s + ":#{mysql_port}" }.join(",")
  mysql_jdbc_url += "#{hostnameport}/#{node['bach_ambari']['databasename']}"

  db_opts += " --database=#{node['bach_ambari']['db_type']}"
  db_opts += " --databasehost=#{node['bach_ambari']['embeddeddbhost']}"
  db_opts += " --databaseport=#{mysql_port}"
  db_opts += " --databasename=#{node['bach_ambari']['databasename']}"
  db_opts += " --databaseusername=#{node['bach_ambari']['databaseusername']}"
  db_opts += " --databasepassword=#{node['bach_ambari']['databasepassword']}"

when 'embedded'
  db_opts = ''
else
  raise "database #{node['bach_ambari']['db_type']} is not supported "
end


execute 'ambari-server setup -s' do
  command "ambari-server setup #{db_opts} -s #{java_opts}"
end


if node['bach_ambari']['kerberos']['enabled']
  execute 'ambari-Server setup-security' do
    command "ambari-server setup-security --security-option=setup-kerberos-jaas --jaas-principal=#{node['bach_ambari']['kerberos']['principal']} --jaas-keytab=#{node['bach_ambari']['kerberos']['keytab']['location']}"
  end
end

# service 'ambari-server status' do
#   supports :status => true
#   status_command 'ambari-server status'
# #  action :start
# end

java_properties 'ambari.properties' do
  properties_file "#{node['bach_ambari']['ambari_server_conf_dir']}/ambari.properties"
  if node['bach_ambari']['db_type'] == 'mysql'
    property 'server.jdbc.url', "#{mysql_jdbc_url}"
  end
  property 'server.startup.web.timeout', "#{node['bach_ambari']['ambari-server-startup-web-timeout']}"
end

execute 'ambari-server start' do
  # only_if 'template "#{config_dir}/ambari.prorperties"'
  command 'ambari-server start'
  not_if 'ambari-server status'
end

# service 'ambari-serve' do
#   supports :status => true
#   action :start
# #  action :start
# end
