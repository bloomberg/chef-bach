include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::oozie_config'

dpkg_autostart "oozie" do
  allow false
end

#%w{libmysql-java zip unzip extjs hadoop-lzo oozie oozie-client}.each do |pkg|
%w{zip unzip extjs hadoop-lzo oozie oozie-client}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

template "/etc/init.d/oozie" do
  source "hdp_oozie-initd.erb"
  mode 0655
end

OOZIE_LIB_PATH='/usr/hdp/current/oozie'
OOZIE_CLIENT_PATH='/usr/hdp/current/oozie-client'
OOZIE_SERVER_PATH='/usr/hdp/2.2.0.0-2041/oozie-server'
HDFS_URL="hdfs://#{node.chef_environment}/"

directory "#{OOZIE_LIB_PATH}/libext" do
  owner "oozie"
  group "oozie"
  mode 00755
  action :create
  recursive true
end

directory "/var/run/oozie" do
  owner "oozie"
  group "oozie"
  mode 00755
  action :create
  recursive true
end

#bash "copy hadoop libs" do
#  src_dir="/usr/hdp/2.2.0.0-2041/hadoop/lib"
#  dst_dir="#{OOZIE_LIB_PATH}/libext/"
#  code "for f in `ls *.jar`; do ln -s #{src_dir}/$f #{dst_dir}/$f; done"
#  cwd src_dir
#  user "oozie"
#  # check if all source files are in destination directory
#  not_if { (::Dir.entries("#{src_dir}") - ::Dir.entries("#{dst_dir}")).empty? }
#end

%w{/usr/share/HDP-oozie/ext-2.2.zip
   /usr/share/java/mysql-connector-java.jar
   /usr/lib/hadoop/lib/hadoop-lzo-0.6.0.jar}.each do |path|
  link "#{OOZIE_CLIENT_PATH}/libext/#{File.basename(path)}" do
    to path
  end
end

bash "copy" do
  code "cp -r /usr/hdp/2.2.0.0-2041/oozie/tomcat-deployment/conf/ssl /usr/hdp/current/oozie-server/conf/"
end

service "stop-oozie-for-war-setup" do
  action :stop
  supports :status => true, :restart => true, :reload => false
  service_name "oozie"
  supports :status => true, :restart => true, :reload => false
  only_if {not File.exists?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") or
           File.mtime("#{OOZIE_CLIENT_PATH}/libext/") > File.mtime("#{OOZIE_SERVER_PATH}/webapps/oozie.war") }
end

bash "oozie_setup_war" do
# code "#{OOZIE_LIB_PATH}/bin/oozie-setup.sh prepare-war"
  code "#{OOZIE_CLIENT_PATH}/bin/oozie-setup.sh prepare-war"
  only_if {not File.exists?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") or
           File.mtime("#{OOZIE_CLIENT_PATH}/libext/") > File.mtime("#{OOZIE_SERVER_PATH}/webapps/oozie.war") }
  returns [0]
end

bash "make_shared_libs_dir" do
  code <<EOH
  hdfs dfs -mkdir -p #{HDFS_URL}/user/oozie/share/ && \
  hdfs dfs -chown -R oozie #{HDFS_URL}/user/oozie/
EOH
  user "hdfs"
  not_if "hdfs dfs -test #{HDFS_URL}/user/oozie/share/", :user => "hdfs"
end

bash "oozie_update_shared_libs" do
  share_dir_url="#{HDFS_URL}/user/oozie/share/"
  #code "#{OOZIE_LIB_PATH}/bin/oozie-setup.sh sharelib update -fs #{HDFS_URL}"
  code "#{OOZIE_CLIENT_PATH}/bin/oozie-setup.sh sharelib upgrade -fs #{HDFS_URL}"
  user "oozie"
  not_if "hdfs dfs -test -d #{HDFS_URL}/user/oozie/share/lib", :user => "hdfs"
  #not_if { require 'time'
  #         hdfs_mtime=`hdfs dfs -stat #{share_dir_url}`.strip
  #         Time.parse("#{hdfs_mtime} UTC") >
  #         File.mtime("#{OOZIE_CLIENT_PATH}/oozie-sharelib.tar.gz") }
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

template "/etc/oozie/conf.#{node.chef_environment}/action-conf/hive.xml" do
  mode 0644
  source "ooz_action_hive.xml.erb"
end

file "#{OOZIE_CLIENT_PATH}/oozie.sql" do
  owner "oozie"
  group "oozie"
end

ruby_block "oozie-database-creation" do
  cmd = "mysql -uroot -p#{get_config('mysql-root-password')} -e"
  privs = "CREATE,INDEX,SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE"
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
      #system "sudo -u oozie #{OOZIE_CLIENT_PATH}/bin/ooziedb.sh create -sqlfile #{OOZIE_CLIENT_PATH}/oozie.sql -run Validate DB Connection"
      system "sudo -u oozie /usr/hdp/2.2.0.0-2041/oozie/bin/ooziedb.sh create -sqlfile /usr/hdp/2.2.0.0-2041/oozie/oozie.sql -run Validate DB Connection"
      self.resolve_notification_references
    end
  end
end

service "generally run oozie" do
  action [:enable, :start]
  service_name "oozie"
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/oozie/conf/oozie-site.xml]", :delayed
  subscribes :restart, "template[/etc/oozie/conf/oozie-env.sh]", :delayed
end

ruby_block "Oozie Down" do
  i = 0
  block do
    status=`oozie admin -oozie http://localhost:11000/oozie -status 2>&1` 
    while not /NORMAL/ =~ status and $?.to_i
      status=`oozie admin -oozie http://localhost:11000/oozie -status 2>&1` 
      if $?.to_i != 0 and i < 10
        sleep(0.5)
        i += 1
        Chef::Log.debug("Oozie is down - #{status}")
      elsif $?.to_i != 0
        raise Chef::Application.fatal! "Oozie is reported as down for more than 5 seconds -- #{status}"
      else
        Chef::Log.debug("Oozie status is not failing - #{status}")
      end
    end
    Chef::Log.debug("Oozie is up - #{status}")
  end
  not_if "oozie admin -oozie http://localhost:11000/oozie -status"
end
