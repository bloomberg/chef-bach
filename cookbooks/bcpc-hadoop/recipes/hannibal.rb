# Setup hannibal config

# Populate node attributes for all kind of hosts
set_hosts

make_bcpc_config('hannibal-app-secret-key', secure_password(64))
make_bcpc_config('hannibal-db-user', "hannibal")
make_bcpc_config('hannibal-db-password', secure_password)

if(node[:hannibal][:local_tarball]) then
   node.override[:hannibal][:download_url] = get_binary_server_url
end

node.override[:hannibal][:db] = "mysql"
node.override[:hannibal][:mysql][:db_name] = 'hannibal' 
node.override[:hannibal][:mysql][:driver] = 'com.mysql.jdbc.Driver' 
node.override[:hannibal][:mysql][:url] = "\"jdbc:mysql://#{node[:bcpc][:management][:vip]}/hannibal?characterEncoding=UTF-8\""
node.override[:hannibal][:app_secret_key] = get_bcpc_config('hannibal-app-secret-key') 
node.override[:hannibal][:db_user] = get_bcpc_config('hannibal-db-user') 
node.override[:hannibal][:db_password] = get_bcpc_config('hannibal-db-password')

if ("mysql" == node[:hannibal][:db]) then
# Create DB, User and configure permissions for hannibal
   ruby_block "hannibal-database-creation" do
      block do
            puts %x[ mysql -u#{get_bcpc_config('mysql-root-user')} -p#{get_bcpc_config('mysql-root-password')} -e "CREATE DATABASE #{node[:hannibal][:mysql][:db_name]} CHARACTER SET UTF8;"
                     mysql -u#{get_bcpc_config('mysql-root-user')} -p#{get_bcpc_config('mysql-root-password')} -e "GRANT ALL ON #{node[:hannibal][:mysql][:db_name]}.* TO '#{get_bcpc_config('hannibal-db-user')}'@'%' IDENTIFIED BY '#{get_bcpc_config('hannibal-db-password')}';"
                     mysql -u#{get_bcpc_config('mysql-root-user')} -p#{get_bcpc_config('mysql-root-password')} -e "GRANT ALL ON #{node[:hannibal][:mysql][:db_name]}.* TO '#{get_bcpc_config('hannibal-db-user')}'@'localhost' IDENTIFIED BY '#{get_bcpc_config('hannibal-db-password')}';"
                     mysql -u#{get_bcpc_config('mysql-root-user')} -p#{get_bcpc_config('mysql-root-password')} -e "FLUSH PRIVILEGES;"
                  ]
      end
      not_if "mysql -u#{get_bcpc_config('mysql-root-user')} -p#{get_bcpc_config('mysql-root-password')} -e \"SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \'#{node[:hannibal][:mysql][:db_name]}\'\" | grep #{node[:hannibal][:mysql][:db_name]}" 
   end
end

node.override[:hannibal][:zookeeper_quorum] = node[:bcpc][:hadoop][:zookeeper][:servers] 
node.override[:hannibal][:hbase_rs][:info_port] = 60300
