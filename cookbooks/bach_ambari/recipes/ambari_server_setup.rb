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


String dbhostname = node['bach_ambari']['databasehost'].map { |m| m.to_s }.first

if node['bach_ambari']['db_type'] == 'mysql'
  execute 'execute create ambari database' do
    command "mysql -u root -p#{node['bach_ambari']['mysql_root_password']} -h #{dbhostname} -e 'CREATE DATABASE IF NOT EXISTS #{node['bach_ambari']['databasename']}'"
  end

  # execute 'execute create ambari user' do
  #   command "mysql -u root -p#{node['bach_ambari']['mysql_root_password']} -h #{dbhostname} -e 'CREATE USER \"#{node['bach_ambari']['databaseusername']}\"@ IDENTIFIED BY \"#{node['bach_ambari']['databasepassword']}\" '"
  # end

  execute 'execute grant all PRIVILEGES' do
    command "mysql -u root -p#{node['bach_ambari']['mysql_root_password']} -h #{dbhostname} -e 'GRANT ALL ON #{node['bach_ambari']['databasename']}.* TO \"#{node['bach_ambari']['databaseusername']}\"@ IDENTIFIED BY \"#{node['bach_ambari']['databasepassword']}\"'"
  end
  execute 'execute FLUSH PRIVILEGES' do
    command "mysql -u root -p#{node['bach_ambari']['mysql_root_password']} -h #{dbhostname} -e 'FLUSH PRIVILEGES'"
  end

  # mysql2_chef_gem 'default' do
  #   action :install
  # end

  # mysql_connection_info = {
  #   :host => "#{dbhostname}",
  #   :username => 'root',
  #   :password => node['bach_ambari']['mysql_root_password']
  # }
  #
  # mysql_database "#{node['bach_ambari']['databasename']}" do
  #   connection   mysql_connection_info
  #   action   :create
  # end
  #
  # mysql_database_user "#{node['bach_ambari']['databaseusername']}" do
  #   connection   mysql_connection_info
  #   password   node['bach_ambari']['databasepassword']
  #   action   :create
  # end
  #
  # mysql_database_user "#{node['bach_ambari']['databaseusername']}" do
  #   connection   mysql_connection_info
  #   database_name   "#{node['bach_ambari']['databasename']}"
  #   host   '%'
  #   privileges   ['ALL PRIVILEGES']
  #   action   :grant
  # end

end

if node['bach_ambari']['db_type'] == 'mysql'
  execute 'execute mysql schema script' do
    command "mysql -u #{node['bach_ambari']['databaseusername']} -p#{node['bach_ambari']['databasepassword']} #{node['bach_ambari']['databasename']} -h #{dbhostname} <#{node['bach_ambari']['mysql_schema_path']}"
    not_if { c = Mixlib::ShellOut.new("mysql -u #{node['bach_ambari']['databaseusername']} -p#{node['bach_ambari']['databasepassword']} #{node['bach_ambari']['databasename']} -h #{dbhostname} --skip-column-names -e 'SELECT count(*) FROM clusters'")
        c.run_command
        c.status.success?
    }
  end
end

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
