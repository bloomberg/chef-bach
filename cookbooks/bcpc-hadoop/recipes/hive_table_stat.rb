#
# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_table_stat
# Description : create database for hive table statistics 
#

#mysql_connection_info = {
#  :host     => '127.0.0.1',
#  :username => 'root',
#  :password => get_config('mysql-root-password')
#}

#mysql_database node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"] do
#  connection mysql_connection_info 
#  action :create
#end

#mysql_database_user node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"] do
#  connection mysql_connection_info 
#  password get_config("mysql-hive-table-stats-password") 
#  action :create
#end



ruby_block "hive_table_stats_db" do
  cmd = "mysql -uroot -p#{get_config!('password','mysql-root','os')} -e"
  privs = "ALL" # todo node[:bcpc][:hadoop][:hive_db_privs].join(",")
  block do
    if not system " #{cmd} 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]}' | grep -q #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]}" then
      code = <<-EOF
        CREATE DATABASE #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]};
        GRANT #{privs} ON #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]}.* TO '#{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"]}'@'%' IDENTIFIED BY '#{get_config('mysql-hive-table-stats-password')}';
        EOF
      IO.popen("mysql -uroot -p#{get_config!('password','mysql-root','os')}", "r+") do |db|
        db.write code
      end
      self.notifies :enable, "service[hive-metastore]", :delayed
      self.resolve_notification_references
    end
  end
end

