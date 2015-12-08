#
#  Installing Hive & Hcatalog
#
include_recipe "bcpc-hadoop::hive_config"
include_recipe "bcpc-hadoop::hive_table_stat"

package "hive-hcatalog" do
  action :upgrade
end

package "hadoop-lzo" do
  action :upgrade
end

user_ulimit "hive" do
  filehandle_limit 32769
  process_limit 65536
end

link "/usr/hdp/2.2.0.0-2041/hadoop/lib/hadoop-lzo-0.6.0.jar" do
  to "/usr/lib/hadoop/lib/hadoop-lzo-0.6.0.jar"
end

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

link "/usr/hdp/current/mysql-connector-java.jar" do
  to "/usr/share/java/mysql.jar"
end

bash "create-hive-user-home" do
  code <<-EOH
  hdfs dfs -mkdir -p /user/hive
  hdfs dfs -chmod 1777 /user/hive
  hdfs dfs -chown hive:hdfs /user/hive
  EOH
  user "hdfs"
end

bash "create-hive-warehouse" do
  code <<-EOH
  hdfs dfs -mkdir -p /apps/hive/warehousehadoop
  hdfs dfs -chmod -R 775 /apps/hive
  hdfs dfs -chown -R hive:hdfs /apps/hive
  EOH
  user "hdfs"
end

bash "create-hive-scratch" do
  code <<-EOH
  hdfs dfs -mkdir -p /tmp/scratch
  hdfs dfs -chmod -R 1777 /tmp/scratch
  hdfs dfs -chown -R hive:hdfs /tmp/scratch
  EOH
  user "hdfs"
end

ruby_block "hive-metastore-database-creation" do
  cmd = "mysql -uroot -p#{get_bcpc_config('mysql-root-password')} -e"
  privs = "SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE" # todo node[:bcpc][:hadoop][:hive_db_privs].join(",")
  block do
    if not system " #{cmd} 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"metastore\"' | grep -q metastore" then
      code = <<-EOF
        CREATE DATABASE metastore;
        GRANT #{privs} ON metastore.* TO 'hive'@'%' IDENTIFIED BY '#{get_bcpc_config('mysql-hive-password')}';
        GRANT #{privs} ON metastore.* TO 'hive'@'localhost' IDENTIFIED BY '#{get_bcpc_config('mysql-hive-password')}';
        FLUSH PRIVILEGES;
        USE metastore;
        SOURCE /usr/hdp/current/hive-metastore/scripts/metastore/upgrade/mysql/hive-schema-0.14.0.mysql.sql;
        EOF
      IO.popen("mysql -uroot -p#{get_bcpc_config('mysql-root-password')}", "r+") do |db|
        db.write code
      end
      self.notifies :enable, "service[hive-metastore]", :delayed
      self.resolve_notification_references
    end
  end
end

#bash "create-hive-metastore-db" do
#  code <<-EOH
#  /usr/hdp/2.2.0.0-2041/hive/bin/schematool -initSchema -dbType mysql -verbose
#  EOH
#end

template "/etc/init.d/hive-metastore" do
  source "hdp_hive-metastore-initd.erb"
  mode 0655
end

template "/etc/init.d/hive-server2" do
  source "hdp_hive-server2-initd.erb"
  mode 0655
end

directory "/var/log/hive/gc" do
  action :create
  mode 0755
  user "hive"
end

service "hive-metastore" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
  subscribes :restart, "bash[extract-mysql-connector]", :delayed
  subscribes :restart, "directory[/var/log/hive/gc]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
end

service "hive-server2" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
  subscribes :restart, "bash[extract-mysql-connector]", :delayed
  subscribes :restart, "directory[/var/log/hive/gc]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
end
