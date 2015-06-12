
ambari_repo_url = "http://public-repo-1.hortonworks.com/ambari/ubuntu12/2.x/updates/2.0.0/ambari.list"
hdp_repo_url = "http://public-repo-1.hortonworks.com/HDP/ubuntu12/2.x/updates/2.2.4.2/hdp.list"
repo_dir = "/etc/apt/sources.list.d"
ambari_server_ip="192.168.100.12"
ambari_uri="http://#{ambari_server_ip}:8080/api/v1/views/TEZ/versions/0.5.2.2.2.2.0-151/instances"
instance_name="Tez1"
yarn_timelineserver_url="http://10.0.100.12:8188"
yarn_resourcemanager_url="http://192.168.100.12:8088"
AMBARIUSER="ambari"
AMBARIPASSWORD="bigdata"
AMBARISERVERFQDN="f-bcpc-vm2"
AMBARIDATABASE="ambari"


bash "download_repo" do
code <<EOH
wget -nv #{ambari_repo_url} -O /etc/apt/sources.list.d/ambari.list
apt-key adv --recv-keys --keyserver
wget #{hdp_repo_url}  -O /etc/apt/sources.list.d/hdp.list
apt-get update
EOH
end

%w{ambari-server tez }.each do |pkg|
  package pkg do
    action :install
  end
end

#Code block for Ambari server backend database setup(mysql)
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

if ("mysql" == "mysql" ) then
ruby_block "ambari-database-creation" do
      block do
AMBARIUSER="ambari"
AMBARIPASSWORD="bigdata"
AMBARISERVERFQDN="f-bcpc-vm2"
AMBARIDATABASE="ambari"
puts %x[ mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE DATABASE #{AMBARIDATABASE} CHARACTER SET UTF8;"
mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{AMBARIDATABASE}.* TO '#{AMBARIUSER}'@'%' IDENTIFIED BY '#{AMBARIPASSWORD}';"
mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{AMBARIDATABASE}.* TO '#{AMBARIUSER}'@'localhost' IDENTIFIED BY '#{AMBARIPASSWORD}';"
#mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE USER '#{AMBARIUSER}'@'#{AMBARISERVERFQDN}' IDENTIFIED BY '#{AMBARIPASSWORD}';"
#mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE USER '#{AMBARIUSER}'@'localhost' IDENTIFIED BY '#{AMBARIPASSWORD}';"
#mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE USER '#{AMBARIUSER}'@'%' IDENTIFIED BY '#{AMBARIPASSWORD}';"
mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "USE #{AMBARIDATABASE};SOURCE /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql;"
mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "FLUSH PRIVILEGES;"
]
end
      not_if "mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e \"SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \'#{AMBARIDATABASE}\'\" | grep #{AMBARIDATABASE} "
   end
end

execute "setup ambari-server" do
  command "ambari-server setup -s"
end

template "/etc/ambari-server/conf/ambari.properties" do
  source "ambari.properties.erb"
end

#Starting multiple services in one block

%w{ambari-server }.each do |pkg|
service pkg do
  action [:enable, :start]
end
end


template "/etc/init.d/hadoop-yarn-timelineserver" do
  source "hdp_hadoop-yarn-timelineserver-initd.erb"
  mode 0655
end

service "hadoop-yarn-timelineserver" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
end


execute "create tez view instance" do
command "curl -H \"X-Requested-By:ambari\" -u admin:admin -X POST -d '[{ \"ViewInstanceInfo\" : { \"label\" : \"Tez custom View\", \"properties\" : {\"yarn.timeline-server.url\" : \"#{yarn_timelineserver_url}\", \"yarn.resourcemanager.url\" : \"#{yarn_resourcemanager_url}\" } } } ]' #{ambari_uri}/#{instance_name}"
only_if {"curl -s -H \"X-Requested-By:ambari\" -u admin:admin -X GET #{ambari_uri}/#{instance_name} | grep instance_name | tr -d \", | head -1 | awk -F ':' '{print $2}'|tr -d ' '" != "#{instance_name}"}
notifies :restart, 'service[ambari-server]', :immediately
end

