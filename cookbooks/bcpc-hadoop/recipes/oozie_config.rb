# Cookbook Name : bcpc-hadoop
# Recipe Name : oozie_config
# Description : To setup oozie configuration only.

# Create oozie realted passwords
make_config('oozie-keystore-password', secure_password)
make_config('mysql-oozie-password', secure_password)

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
    mode 0644
    variables(:mysql_hosts => node[:bcpc][:hadoop][:mysql_hosts].map{ |m| m[:hostname] },
              :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
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
