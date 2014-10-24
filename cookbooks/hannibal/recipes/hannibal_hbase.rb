# Download, configure and start hannibal

hbase_version = "#{node[:hannibal][:hbase_version]}"
src_filename = "hannibal-hbase#{hbase_version}.tgz"
src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
install_dir = "#{node[:hannibal][:install_dir]}"
log_dir = "#{node[:hannibal][:log_dir]}"
data_dir = "#{node[:hannibal][:data_dir]}"
service_dir = "#{node[:hannibal][:service_dir]}"
owner = "#{node[:hannibal][:owner]}"
group = "#{node[:hannibal][:group]}"
user = "#{node[:hannibal][:user]}"
file_mode = "#{node[:hannibal][:file_mode]}"
exec_mode = "#{node[:hannibal][:exec_mode]}"
endpoint = "#{node[:hannibal][:service_endpoint]}"
timeout = node[:hannibal][:service_timeout]

make_config('hannibal-app-secret-key', secure_password(64))
make_config('hannibal-db-user', "hannibal")
make_config('hannibal-db-password', secure_password)

if(node[:hannibal][:local_tarball]) then
   tarball_location = "#{get_binary_server_url}#{src_filename}"
else
   tarball_location = "#{node[:hannibal][:download_url]}/#{src_filename}"
end

# Only download if not already extracted in /usr/lib/hannibal
remote_file src_filepath do
   source tarball_location
   if(!node[:hannibal][:local_tarball]) then
      checksum "#{node[:hannibal][:checksum]["#{hbase_version}"]}"
   end
   notifies :run, "bash[unzip_hannibal]", :immediately
   not_if { ::File.exists?("#{install_dir}/hannibal") }
end

# Only download if not already extracted in /usr/lib/hannibal
# Could have remote_file notify this script, but this is to handle manual deletion of
# hannibal install dir
bash "unzip_hannibal" do
   cwd ::File.dirname(src_filepath)
   code %Q{
      tar -xf #{src_filename} -C #{install_dir}/
      chown -R #{owner}:#{group} #{install_dir}/hannibal
   }
   not_if { ::File.exists?("#{install_dir}/hannibal") }
end

["#{log_dir}", "#{data_dir}"].each do |d|
   directory d do
      recursive true   
      owner user
      action :create
   end
end

file "#{log_dir}/service.log" do
   owner user
   action :create_if_missing 
end

template "hbase_site" do
   path "#{install_dir}/hannibal/conf/hbase-site.xml"
   source "hannibal_hbase-site.xml.erb"
   owner owner
   group group
   mode file_mode
   variables(:zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers])
end

template "logger" do
   path "#{install_dir}/hannibal/conf/logger.xml"
   source "hannibal_logger.xml.erb"
   owner owner
   group group
   mode file_mode
end

template "application_conf" do
   path "#{install_dir}/hannibal/conf/application.conf"
   source "hannibal_application.conf.erb"
   owner owner
   group group
   mode file_mode
end

template "start_script" do
   path "#{install_dir}/hannibal/start"
   source "hannibal_start.erb"
   owner owner
   group group
   mode exec_mode
end

template "hannibal_service" do
   path "#{service_dir}/hannibal.conf"
   source "hannibal.upstart.conf.erb"
   owner owner
   group group
   mode file_mode
end

%w{ 1 2 3 4 5
}.each do |n|
   template "hannibal_#{n}.sql" do
      path "#{install_dir}/hannibal/conf/evolutions/default/#{n}.sql"
      source "hannibal_#{n}.sql.erb"
      owner owner
      group group
   end
end

if ("mysql" == "#{node[:hannibal][:db]}") then
# Create DB, User and configure permissions for hannibal
   ruby_block "hannibal-database-creation" do
      block do
         if not system "mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = \"#{node[:hannibal][:mysql][:db_name]}\"'|grep \"#{node[:hannibal][:mysql][:db_name]}\"" then
            puts %x[ mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "CREATE DATABASE #{node[:hannibal][:mysql][:db_name]} CHARACTER SET UTF8;"
                     mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{node[:hannibal][:mysql][:db_name]}.* TO '#{get_config('hannibal-db-user')}'@'%' IDENTIFIED BY '#{get_config('hannibal-db-password')}';"
                     mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "GRANT ALL ON #{node[:hannibal][:mysql][:db_name]}.* TO '#{get_config('hannibal-db-user')}'@'localhost' IDENTIFIED BY '#{get_config('hannibal-db-password')}';"
                     mysql -u#{get_config('mysql-root-user')} -p#{get_config('mysql-root-password')} -e "FLUSH PRIVILEGES;"
                  ]
            puts "Created DB '#{node[:hannibal][:mysql][:db_name]}'."
         else
            puts "DB '#{node[:hannibal][:mysql][:db_name]}' already exists."
         end
      end
   end
end 

hannibal_dir = "#{install_dir}/hannibal"

# Set directory permissions
[hannibal_dir, "#{hannibal_dir}/share", "#{hannibal_dir}/lib", "#{hannibal_dir}/bin", "#{hannibal_dir}/conf", "#{hannibal_dir}/start"].each do |d|
   directory d do
      mode '0755' 
   end
end

bash "set_hannibal_file_permissions" do
   cwd "#{hannibal_dir}"
   code %Q{
      chmod '0644' ./lib/*
      chmod '0644' ./conf/*
      chmod -R '0755' ./conf/evolutions
   }
end

service "hannibal" do
   provider Chef::Provider::Service::Upstart
   action [:start]
end

# Confirm service did start; try until timeout and fail 
ruby_block "wait_for_hannibal" do
   block do
      wait_until_ready(endpoint, timeout)
   end
end
