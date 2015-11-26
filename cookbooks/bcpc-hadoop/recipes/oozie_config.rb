# Cookbook Name : bcpc-hadoop
# Recipe Name : oozie_config
# Description : To setup oozie configuration only.

# Create oozie realted passwords
oozie_keystore_password = get_config("oozie-keystore-password")
if oozie_keystore_password.nil?
  oozie_keystore_password = secure_password
end

mysql_oozie_password = get_config("mysql-oozie-password")
if mysql_oozie_password.nil?
  mysql_oozie_password = secure_password
end

bootstrap = get_bootstrap
results = get_nodes_for("oozie_config").map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results

chef_vault_secret "oozie-keystore" do
  data_bag 'hadoop'
  raw_data({ 'password' => oozie_keystore_password })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

chef_vault_secret "mysql-oozie" do
  data_bag 'hadoop'
  raw_data({ 'password' => mysql_oozie_password })
  admins "#{ nodes },#{ bootstrap }"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

directory "/etc/oozie/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

bash "update-oozie-conf-alternatives" do
  code %Q{
    update-alternatives --install /etc/oozie/conf oozie-conf /etc/oozie/conf.#{node.chef_environment} 50
    update-alternatives --set oozie-conf /etc/oozie/conf.#{node.chef_environment}
  }
end

#
# Set up oozie config files
#
%w{
  oozie-env.sh
  oozie-site.xml
  adminusers.txt
  oozie-default.xml
  oozie-log4j.properties
  }.each do |t|
  template "/etc/oozie/conf/#{t}" do
    source "ooz_#{t}.erb"
    if t == "oozie-site.xml"
      mode 0640
    else
      mode 0644
    end
    variables(:mysql_hosts => node[:bcpc][:hadoop][:mysql_hosts].map{ |m| m[:hostname] },
              :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
              :ooz_hosts => node[:bcpc][:hadoop][:oozie_hosts],
              :hive_hosts => node[:bcpc][:hadoop][:hive_hosts])
  end
end

link "/etc/oozie/conf.#{node.chef_environment}/hive-site.xml" do
  to "/etc/hive/conf.#{node.chef_environment}/hive-site.xml"
end

link "/etc/oozie/conf.#{node.chef_environment}/core-site.xml" do
  to "/etc/hadoop/conf.#{node.chef_environment}/core-site.xml"
end

link "/etc/oozie/conf.#{node.chef_environment}/yarn-site.xml" do
  to "/etc/hadoop/conf.#{node.chef_environment}/yarn-site.xml"
end
