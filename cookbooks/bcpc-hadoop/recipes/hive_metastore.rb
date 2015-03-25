# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_metastore
# Description : To setup hive metastore service

require 'digest'

include_recipe "bcpc-hadoop::hive_config"

remote_file "#{Chef::Config[:file_cache_path]}/mysql-connector-java-5.1.34.tar.gz" do
  source "#{get_binary_server_url}/mysql-connector-java-5.1.34.tar.gz"
  owner "root"
  group "root"
  mode "755"
  not_if { File.exists?('/usr/share/java/mysql-connector-java-5.1.34-bin.jar') && (Digest::SHA256.hexdigest File.read "/usr/share/java/mysql-connector-java-5.1.34-bin.jar") == "af1e5f28be112c85ec52a82d94e7a8dc02ede57a182dc2f1545f7cec5e808142" } 
end

bash "extract-mysql-connector" do
  code "tar xvzf #{Chef::Config[:file_cache_path]}/mysql-connector-java-5.1.34.tar.gz -C /usr/share/java --no-anchored mysql-connector-java-5.1.34-bin.jar --strip-components=1"
  action :run
  group "root"
  user "root"
  not_if { File.exists?('/usr/share/java/mysql-connector-java-5.1.34-bin.jar') && (Digest::SHA256.hexdigest File.read "/usr/share/java/mysql-connector-java-5.1.34-bin.jar") == "af1e5f28be112c85ec52a82d94e7a8dc02ede57a182dc2f1545f7cec5e808142" }
end

link "/usr/share/java/mysql-connector-java.jar" do
  to "/usr/share/java/mysql-connector-java-5.1.34-bin.jar"
end

link "/usr/share/java/mysql.jar" do
  to "/usr/share/java/mysql-connector-java.jar"
end

link "/usr/lib/hive/lib/mysql.jar" do
  to "/usr/share/java/mysql.jar"
end

# create metastore defaults
template "hive-metastore-defaults" do
  path "/etc/default/hive-metastore"
  source "hv_hive-default-metastore.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "hive-metastore-service" do
  path "/etc/init.d/hive-metastore"
  source "hv_hive-metastore.erb"
  owner "root"
  group "root"
  mode "0755"
end

template "hive-config" do
  path "/usr/lib/hive/bin/hive-config.sh"
  source "hv_hive-config.sh.erb"
  owner "root"
  group "root"
  mode "0755"
end

ruby_block "hive-metastore-database-creation" do
  cmd = "mysql -uroot -p#{get_config('mysql-root-password')} -e"
  privs = "SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE" # todo node[:bcpc][:hadoop][:hive_db_privs].join(",")
  block do
    if not system " #{cmd} 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"metastore\"' | grep -q metastore" then
      code = <<-EOF
        CREATE DATABASE metastore;
        GRANT #{privs} ON metastore.* TO 'hive'@'%' IDENTIFIED BY '#{get_config('mysql-hive-password')}';
        GRANT #{privs} ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY '#{get_config('mysql-hive-password')}';
        FLUSH PRIVILEGES;
        USE metastore;
        SOURCE /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-0.12.0.mysql.sql;
        EOF
      IO.popen("mysql -uroot -p#{get_config('mysql-root-password')}", "r+") do |db|
        db.write code
      end
      self.notifies :enable, "service[hive-metastore]", :delayed
      self.resolve_notification_references
    end
  end
end

service "hive-metastore" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
  subscribes :restart, "bash[extract-mysql-connector]", :delayed
end
