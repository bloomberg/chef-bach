mysql_hosts = node['bcpc']['hadoop']['mysql_hosts'].map { |m| m[:hostname] }
node.default['ambari']['databasehost'] = mysql_hosts
mysql_root_password = get_config('mysql-root-password') || get_config('password', 'mysql-root', 'os')
dbhostname = mysql_hosts.map { |m| m.to_s }.first

execute 'execute create ambari database' do
  command "mysql -u root -p#{mysql_root_password} -h #{dbhostname} -e 'CREATE DATABASE IF NOT EXISTS #{node['ambari']['databasename']}'"
end

execute 'execute grant all PRIVILEGES' do
  command "mysql -u root -p#{mysql_root_password} -h #{dbhostname} -e 'GRANT ALL ON #{node['ambari']['databasename']}.* TO \"#{node['ambari']['databaseusername']}\"@ IDENTIFIED BY \"#{node['ambari']['databasepassword']}\"'"
end

execute 'execute FLUSH PRIVILEGES' do
  command "mysql -u root -p#{mysql_root_password} -h #{dbhostname} -e 'FLUSH PRIVILEGES'"
end


mysql_jdbc_url = "jdbc:mysql://"
mysql_port = node['ambari']['databaseport']
hostnameport = node['ambari']['databasehost'].map { |m| m.to_s + ":#{mysql_port}" }.join(",")
mysql_jdbc_url += "#{hostnameport}/#{node['ambari']['databasename']}"

node.default['ambari']['mysql_jdbc_url'] = mysql_jdbc_url

execute 'execute mysql schema script' do
  command "mysql -u #{node['ambari']['databaseusername']} -p#{node['ambari']['databasepassword']} #{node['ambari']['databasename']} -h #{dbhostname} <#{node['ambari']['mysql_schema_path']}"
  not_if { c = Mixlib::ShellOut.new("mysql -u #{node['ambari']['databaseusername']} -p#{node['ambari']['databasepassword']} #{node['ambari']['databasename']} -h #{dbhostname} --skip-column-names -e 'SELECT count(*) FROM clusters'")
      c.run_command
      c.status.success?
  }
end
