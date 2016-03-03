#
# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_config
# Description : To setup hive configuration only. No hive package will be installed through this Recipe
#


#Create hive password
hive_password = make_config('mysql-hive-password', secure_password)

# Hive table stats user
stats_user = make_config('mysql-hive-table-stats-user',
                         node["bcpc"]["hadoop"]["hive"]["hive_table_stats_db_user"])
stats_password = make_config('mysql-hive-table-stats-password', secure_password)

%w{hive webhcat hcat hive-hcatalog}.each do |w|
  directory "/etc/#{w}/conf.#{node.chef_environment}" do
    owner "root"
    group "root"
    mode 00755
    action :create
    recursive true
  end

  bash "update-#{w}-conf-alternatives" do
    code %Q{
      update-alternatives --install /etc/#{w}/conf #{w}-conf /etc/#{w}/conf.#{node.chef_environment} 50
      update-alternatives --set #{w}-conf /etc/#{w}/conf.#{node.chef_environment}
    }
  end
end

# Set up hive configs
template "/etc/hive/conf/hive-env.sh" do
  source "hv_hive-env.sh.erb"
  mode 0644
  variables(
    :java_home => node[:bcpc][:hadoop][:java],
    :hadoop_heapsize => node[:bcpc][:hive][:heap][:size],
    :hadoop_opts => node[:bcpc][:hive][:gc_opts]
  )
end

template "/etc/hive/conf/hive-exec-log4j.properties" do
  source "hv_hive-exec-log4j.properties.erb"
  mode 0644
end

template "/etc/hive/conf/hive-log4j.properties" do
  source "hv_hive-log4j.properties.erb"
  mode 0644
end

hive_site_vars = {
  :is_hive_server => node.run_list.expand(node.chef_environment).recipes.include?("bcpc-hadoop::hive_hcatalog"),
  :mysql_hosts => node[:bcpc][:hadoop][:mysql_hosts].map{ |m| m[:hostname] },
  :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
  :hive_hosts => node[:bcpc][:hadoop][:hive_hosts],
  :stats_user => stats_user,
  :warehouse => "#{node['bcpc']['hadoop']['hdfs_url']}/user/hive/warehouse",
  :metastore_keytab => "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:keytab]}",
  :server_keytab => "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:keytab]}",
  :kerberos_enabled => node[:bcpc][:hadoop][:kerberos][:enable]
}

hive_site_vars[:hive_sql_password] = \
if node.run_list.expand(node.chef_environment).recipes.include?("bcpc-hadoop::hive_hcatalog") then
  hive_password
else
  ""
end

hive_site_vars[:stats_sql_password] = \
if node.run_list.expand(node.chef_environment).recipes.include?("bcpc-hadoop::hive_hcatalog") then
  stats_password
else
  ""
end

hive_site_vars[:metastore_princ] = \
if node.run_list.expand(node.chef_environment).recipes.include?("bcpc-hadoop::hive_hcatalog") then
  "#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost] == '_HOST' ? float_host(node[:fqdn]) : node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
else
  "#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
end

hive_site_vars[:server_princ] = \
if node.run_list.expand(node.chef_environment).recipes.include?("bcpc-hadoop::hive_hcatalog") then
  "#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost] == '_HOST' ? float_host(node[:fqdn]) : node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
else
  "#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:principal]}/#{node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost] == '_HOST' ? '_HOST' : node[:bcpc][:hadoop][:kerberos][:data][:hive][:princhost]}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
end

template "/etc/hive/conf/hive-site.xml" do
  source "hv_hive-site.xml.erb"
  mode 0644
  variables(:template_vars => hive_site_vars)
end

link "/etc/hive-hcatalog/conf.#{node.chef_environment}/hive-site.xml" do
  to "/etc/hive/conf.#{node.chef_environment}/hive-site.xml"
end
