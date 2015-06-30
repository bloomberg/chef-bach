# Cookbook Name:: ambari-server
# Description : Recipe to install Ambari-server and TEZ libraries on a given host and creates a TEZ View Instance. 


ambari_repo_url = node[:ambari][:repo][:url]
hdp_repo_url = node[:ambari][:hdp][:repo][:url]
repo_dir = node[:ambari][:repo][:dir]

node.set[:ambari][:server]="#{float_host(get_nodes_for("ambari","ambari-server")[0].fqdn)}"
puts "#{float_host(get_nodes_for("ambari","ambari-server")[0].fqdn)}"
ambari_server_ip = node[:ambari][:server]
instance_name = node[:ambari][:view][:instance_name]
AMBARIUSER = node[:ambari][:database][:username]
AMBARISERVERFQDN = node[:ambari][:server]
AMBARIDATABASE = node[:ambari][:database][:name]
yarn_timelineserver_url="http://#{float_host(get_nodes_for("ambari","ambari-server")[0].fqdn)}:8088"
yarn_resourcemanager_url="http://#{float_host(get_nodes_for("ambari","ambari-server")[0].fqdn)}:8188"
ambari_url= "http://#{float_host(get_nodes_for("ambari","ambari-server")[0].fqdn)}:8080/api/v1/views/TEZ/versions/0.5.2.2.2.2.0-151/instances"
make_config('ambari-database-password', secure_password(64))
node.override[:ambari][:database][:password] = get_config('ambari-database-password')
AMBARIPASSWORD = node[:ambari][:database][:password]

#Variables used in creating TEZ view
instance_name = node[:ambari][:view][:instance_name]

remote_file "/tmp/ambari.deb" do
  source "#{get_binary_server_url}/ambari-server-withoutdependencies.deb"
  owner "root"
  group "root"
  mode "755"
mode "0644"
not_if { ::File.exists?("/etc/ambari-server")}
end

bash "Installing Ambari server" do
  code <<EOH
    dpkg -i "/tmp/ambari.deb"
    rm -rf /tmp/ambari.deb
EOH
only_if { ::File.exists?("/tmp/ambari.deb")}
end


%w{tez}.each do |pkg|
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
	puts %x[ mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE DATABASE #{AMBARIDATABASE} CHARACTER SET UTF8;"
	mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{AMBARIDATABASE}.* TO '#{AMBARIUSER}'@'%' IDENTIFIED BY '#{get_config('ambari-database-password')}';"
	mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{AMBARIDATABASE}.* TO '#{AMBARIUSER}'@'localhost' IDENTIFIED BY '#{get_config('ambari-database-password')}';"
	#mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE USER '#{AMBARIUSER}'@'#{AMBARISERVERFQDN}' IDENTIFIED BY '#{get_config('ambari-database-password')}';"
	#mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE USER '#{AMBARIUSER}'@'localhost' IDENTIFIED BY '#{get_config('ambari-database-password')}';"
	#mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE USER '#{AMBARIUSER}'@'%' IDENTIFIED BY '#{get_config('ambari-database-password')}';"
	mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "USE #{AMBARIDATABASE};SOURCE /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql;"
	mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "FLUSH PRIVILEGES;"
]
end
      not_if "mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e \"SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \'#{AMBARIDATABASE}\'\" | grep #{AMBARIDATABASE} "
   end
end

execute "setup ambari-server" do
  command "ambari-server setup -s"
not_if { File.exists?('/etc/ambari-server/conf/ambari.properties')}
end

bash "Setting up Ambari server" do
	code <<EOH
	 sed -i 's/bigdata/#{get_config('ambari-database-password')}/' /etc/ambari-server/conf/password.dat
EOH
end

template "/etc/ambari-server/conf/ambari.properties" do
  source "ambari.properties.erb"
  variables({ jdbc_host: float_host(get_nodes_for("ambari","ambari-server")[0].fqdn), 
              mysql_host: get_node_attributes(HOSTNAME_ATTR_SRCH_KEYS,"mysql","bcpc")[0]['hostname'] 
           })

end

#Starting multiple services in one block

%w{ambari-server }.each do |pkg|
service pkg do
  action [:enable, :start]
end
end

#Code block to create TEZ View Instance

execute "create tez view instance" do
	command "curl -H \"X-Requested-By:ambari\" -u admin:admin -X POST -d '[{ \"ViewInstanceInfo\" : { \"label\" : \"Tez custom View\", \"properties\" : {\"yarn.timeline-server.url\" : \"#{yarn_timelineserver_url}\", \"yarn.resourcemanager.url\" : \"#{yarn_resourcemanager_url}\" } } } ]' #{ambari_url}/#{instance_name}"
	only_if {"curl -s -H \"X-Requested-By:ambari\" -u admin:admin -X GET #{ambari_url}/#{instance_name} | grep instance_name | tr -d \", | head -1 | awk -F ':' '{print $2}'|tr -d ' '" != "#{instance_name}"}
	notifies :restart, 'service[ambari-server]', :immediately
end

