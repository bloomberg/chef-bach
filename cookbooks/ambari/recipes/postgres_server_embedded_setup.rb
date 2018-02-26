# Ambari local database attributes
node.default['postgresql']['assign_postgres_password'] = false
node.default['postgresql']['server']['config_change_notify'] = :reload

# installing postgresql client and server
include_recipe 'postgresql'
include_recipe 'postgresql::server'

# create ambari user and database
execute 'excute embedded postgres script' do
  command "su - postgres --command=\"psql -f #{node['ambari']['pg_db_script_path']} -v username=#{node['ambari']['databaseusername']} -v password=\\\'\'#{node['ambari']['databasepassword']}\'\\\' -v dbname=#{node['ambari']['databasename']}\""
end

# preparing ambari database schema
execute 'excute postgres schema script' do
  command "psql -h localhost -f #{node['ambari']['pg_schema_path']} -U \'#{node['ambari']['databaseusername']}\' -d \'#{node['ambari']['databasename']}\'"
  environment ({'PGPASSWORD' => "#{node['ambari']['databasepassword']}"})
end
