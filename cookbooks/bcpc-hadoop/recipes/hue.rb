Chef::Resource.send(:include, Bcpc::OSHelper)

include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::hue_config'

Bcpc::OSHelper.set_config(node, 'mysql-hue-password', Bcpc::Helper.secure_password)
Bcpc::OSHelper.set_config(node, 'hue-session-key', Bcpc::Helper.secure_password)

bash "hue-database-creation" do
  privs = "ALL" # todo node[:bcpc][:hadoop][:hue_db_privs].join(",")
  code <<-EOH
    mysql -u root -p#{Bcpc::OSHelper.get_config(node, 'mysql-root-password')} -e "CREATE DATABASE desktop;
                                                             GRANT #{privs} ON desktop.* TO 'hue'@'%' IDENTIFIED BY '#{Bcpc::OSHelper.get_config(node, 'mysql-hue-password')}';
                                                             GRANT #{privs} ON desktop.* TO 'hue'@'localhost' IDENTIFIED BY '#{Bcpc::OSHelper.get_config(node, 'mysql-hue-password')}';
                                                             FLUSH PRIVILEGES;"
  EOH
  not_if "mysql -u hue -p#{Bcpc::OSHelper.get_config(node, 'mysql-hue-password')} -e 'SHOW TABLES' desktop"
  self.notifies :start, "service[hue]", :immediately
end

%w{hue-beeswax
   hue-common
   hue-hbase
   hue-impala
   hue-pig
   hue-plugins
   hue-server
   hue
   hue-sqoop
   hue-zookeeper
}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

bash "create-hue-deployment" do
  code "hadoop fs -mkdir -p /user/hue/oozie/deployments; hadoop fs -chmod -R 1777 /user/hue/oozie; hadoop fs -chown -R hue /user/hue"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /user/hue/oozie"
end

bash "create-hue-oozie-workspace" do
  code "hadoop fs -mkdir -p /user/hue/oozie/workspaces; hadoop fs -chmod -R 1777 /user/hue/oozie; hadoop fs -chown -R hue /user/hue"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /user/hue/oozie/workspaces"
end

bash "create-hue-pig" do
  code "hadoop fs -mkdir -p /user/hue/pig/examples; hadoop fs -chmod -R 1777 /user/hue/pig; hadoop fs -chown -R hue /user/hue"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /user/hue/pig/examples"
end

service "hue" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hue/conf/hue.ini]", :delayed
end
