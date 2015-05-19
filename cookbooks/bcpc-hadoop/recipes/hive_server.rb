# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_server2
# Description : To setup hive configuration only. No hive package will be installed through this Recipe

include_recipe "bcpc-hadoop::hive_config"

# create hiveserver2 defaults
template "hive-server2-defaults" do
  path "/etc/default/hive-server2"
  source "hv_hive-default-hiveserver2.erb"
  owner "root"
  group "root"
  mode "0755"
end

# Create startup script for Hive-Server2
template "hive-server2-service" do
  path "/etc/init.d/hive-server2"
  source "hv_hive-server2.erb"
  owner "root"
  group "root"
  mode "0755"
end

link "/usr/hdp/current/hive-server2/lib/mysql-connector-java.jar" do
  to "/usr/share/java/mysql-connector-java.jar"
end

# Start hive-server2 daemon
service "hive-server2" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-env.sh]", :delayed
  subscribes :restart, "bash[extract-mysql-connector]", :delayed
end
