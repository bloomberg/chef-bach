include_recipe 'dpkg_autostart'

dpkg_autostart "oozie" do
  allow false
end

%w{libmysql-java zip unzip extjs hadoop-lzo oozie oozie-client}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

OOZIE_LIB_PATH='/usr/lib/oozie'
OOZIE_SERVER_PATH='/var/lib/oozie/oozie-server'

directory "#{OOZIE_LIB_PATH}/libext" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

link "#{OOZIE_LIB_PATH}/libext/mysql-connector-java.jar" do
  to "/usr/share/java/mysql-connector-java.jar"
end

bash "oozie_setup_war" do
  code "#{OOZIE_LIB_PATH}/bin/oozie-setup.sh prepare-war"
  user "root"
  action :run
  not_if do FileTest.file?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") end
end

directory "#{OOZIE_SERVER_PATH}/work/Catalina/localhost" do
  owner "oozie"
  group "oozie"
  recursive true
end

directory "/var/log/oozie" do
  owner "oozie"
  group "oozie"
  recursive true
end

file "#{OOZIE_LIB_PATH}/oozie.sql" do
  owner "oozie"
  group "oozie"
end

ruby_block "oozie-database-creation" do
  cmd = "mysql -uroot -p#{get_config('mysql-root-password')} -e"
  privs = "CREATE,INDEX,SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE" # todo node[:bcpc][:hadoop][:hive_db_privs].join(",")
  block do

    if not system " #{cmd} 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"oozie\"' | grep oozie" then

      code = <<-EOF
                CREATE DATABASE oozie;
                GRANT #{privs} ON oozie.* TO 'oozie'@'%' IDENTIFIED BY '#{get_config('mysql-oozie-password')}';
                GRANT #{privs} ON oozie.* TO 'oozie'@'localhost' IDENTIFIED BY '#{get_config('mysql-oozie-password')}';
                FLUSH PRIVILEGES;
      EOF
      IO.popen("mysql -uroot -p#{get_config('mysql-root-password')}", "r+") do |db|
        db.write code
      end
      system "sudo -u oozie #{OOZIE_LIB_PATH}/bin/ooziedb.sh create -sqlfile #{OOZIE_LIB_PATH}/oozie.sql -run Validate DB Connection"
#      IO.popen("mysql -uroot -p#{get_config('mysql-root-password')}", "r+") do |db|
#        db.write "USE oozie; SOURCE /tmp/oozie-create.sql"
#      end
#      self.notifies :enable, "service[oozie]", :immediately
      self.resolve_notification_references
    end
  end
end

directory "/etc/oozie/conf.#{node.chef_environment}/action-conf" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

directory "/etc/oozie/conf.#{node.chef_environment}/hadoop-conf" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

link "/etc/oozie/conf.#{node.chef_environment}/hadoop-conf/core-site.xml" do
  to "/etc/hadoop/conf.#{node.chef_environment}/core-site.xml"
end

link "/etc/oozie/conf.#{node.chef_environment}/hadoop-conf/hdfs-site.xml" do
  to "/etc/hadoop/conf.#{node.chef_environment}/hdfs-site.xml"
end

template "/etc/oozie/conf.#{node.chef_environment}/action-conf/hive.xml" do
  mode 0644
  source "ooz_action_hive.xml.erb"
end

#TODO, this probably has dependencies on external services such as yarn and hive as well
#hopefully it starts up later :)
service "oozie" do
#  action [:enable, :start]
  action :nothing
  subscribes :restart, "template[/etc/oozie/conf/oozie-site.xml]", :delayed
  subscribes :restart, "template[/etc/oozie/conf/oozie-env.sh]", :delayed
end

