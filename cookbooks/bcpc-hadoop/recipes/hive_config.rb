#
# Cookbook Name : bcpc-hadoop
# Recipe Name : hive_config
# Description : To setup hive configuration only. No hive package will be installed through this Recipe
#

#
#Create hive password
#
make_config('mysql-hive-password', secure_password)

%w{
  hive
  webhcat
  hcat
  hive-hcatalog
  }.each do |w|
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

#
# Set up hive configs
#
%w{hive-exec-log4j.properties
   hive-log4j.properties
   hive-env.sh
   hive-site.xml }.each do |t|
   template "/etc/hive/conf/#{t}" do
     source "hv_#{t}.erb"
     mode 0644
     variables(:mysql_hosts => node[:bcpc][:hadoop][:mysql_hosts].map{ |m| m.hostname },
               :zk_hosts => node[:bcpc][:zookeeper][:servers],
               :hive_hosts => node[:bcpc][:hadoop][:hive_hosts])
  end
end

link "/etc/hive-hcatalog/conf.#{node.chef_environment}/hive-site.xml" do
  to "/etc/hive/conf.#{node.chef_environment}/hive-site.xml"
end
