# vim: tabstop=2:shiftwidth=2:softtabstop=2 
#
# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_table_stats
# Description : Setup database  to record temporary hive table statistics
#

# Hive table stats user
make_config('mysql-hive-table-stats-user', node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"])

hive_table_stats_passwd = get_config('mysql-hive-table-stats-password')
if hive_table_stats_passwd.nil?
  hive_table_stats_passwd = secure_password
end

bootstrap = get_bootstrap
hive_search = get_nodes_for("hive_table_stats").map!{ |x| x['fqdn'] }.join(",") 
hive_nodes = hive_search == "" ? node['fqdn'] : hive_hosts

chef_vault_secret "mysql-hive-table-stats" do
  data_bag 'os'
  raw_data({ 'password' => hive_table_stats_passwd })
  admins "#{ hive_nodes}, #{ bootstrap }"
  search ""
  action :nothing
end.run_action(:create_if_missing)

ruby_block "hive_table_stats_db" do
  cmd = "mysql -uroot -p#{get_config!('password','mysql-root','os')} -e"
  privs = "ALL" # todo node[:bcpc][:hadoop][:hive_db_privs].join(",")
  block do
    if not system " #{cmd} 'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]}' | grep -q #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]}" then
      code = <<-EOF
        CREATE DATABASE #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]};
        GRANT #{privs} ON #{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db"]}.* TO '#{node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"]}'@'%' IDENTIFIED BY '#{get_config('password', 'mysql-hive-table-stats', 'os')}';
        EOF
      IO.popen("mysql -uroot -p#{get_config!('password','mysql-root','os')}", "r+") do |db|
        db.write code
      end
      self.notifies :enable, "service[hive-metastore]", :delayed
      self.resolve_notification_references
    end
  end
end

