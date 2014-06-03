include_recipe 'dpkg_autostart'

dpkg_autostart "oozie" do
  allow false
end

%w{libmysql-java zip unzip extjs hadoop-lzo oozie oozie-client}.each do |pkg|
  package pkg do
    action :install
  end
end

OOZIE_LIB_PATH='/usr/lib/oozie'
OOZIE_SERVER_PATH='/var/lib/oozie/oozie-server'
HDFS_URL="hdfs://#{node.chef_environment}/"

directory "#{OOZIE_LIB_PATH}/libext" do
  owner "oozie"
  group "oozie"
  mode 00755
  action :create
  recursive true
end

bash "copy hadoop libs" do
  src_dir="/usr/lib/hadoop/client/"
  dst_dir="#{OOZIE_LIB_PATH}/libext/"
  code "for f in `ls *.jar`; do ln -s #{src_dir}/$f #{dst_dir}/$f; done"
  cwd src_dir
  user "oozie"
  # check if all source files are in destination directory
  not_if { (::Dir.entries("#{src_dir}") - ::Dir.entries("#{dst_dir}")).empty? }
end

%w{/usr/share/HDP-oozie/ext-2.2.zip
   /usr/share/java/mysql-connector-java.jar
   /usr/lib/hadoop/lib/hadoop-lzo-0.5.0.jar}.each do |path|
  link "#{OOZIE_LIB_PATH}/libext/#{File.basename(path)}" do
    to path
  end
end

service "stop-oozie-for-war-setup" do
  action :stop
  service_name "oozie"
  only_if {not File.exists?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") or
           File.atime("#{OOZIE_LIB_PATH}/libext/") > File.atime("#{OOZIE_SERVER_PATH}/webapps/oozie.war") and
           `service oozie status` }
end

bash "oozie_setup_war" do
  code "#{OOZIE_LIB_PATH}/bin/oozie-setup.sh prepare-war"
  only_if {not File.exists?("#{OOZIE_SERVER_PATH}/webapps/oozie.war") or
           File.atime("#{OOZIE_LIB_PATH}/libext/") > File.atime("#{OOZIE_SERVER_PATH}/webapps/oozie.war") }
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
  code "#{OOZIE_LIB_PATH}/bin/oozie-setup.sh sharelib update -fs #{HDFS_URL}"
  user "oozie"
  not_if { require 'time'
           hdfs_mtime=`hdfs dfs -stat #{share_dir_url}`.strip
           Time.parse("#{hdfs_mtime} UTC") >
           File.atime("#{OOZIE_LIB_PATH}/oozie-sharelib.tar.gz") }
end

file "#{OOZIE_LIB_PATH}/oozie.sql" do
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
      system "sudo -u oozie #{OOZIE_LIB_PATH}/bin/ooziedb.sh create -sqlfile #{OOZIE_LIB_PATH}/oozie.sql -run Validate DB Connection"
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

template "/etc/oozie/conf.#{node.chef_environment}/action-conf/hive.xml" do
  mode 0644
  source "ooz_action_hive.xml.erb"
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
