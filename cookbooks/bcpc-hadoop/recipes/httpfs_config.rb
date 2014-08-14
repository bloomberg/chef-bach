# Cookbook Name : bcpc-hadoop
# Recipe Name  : httpfs_config
# Description : To setup hadoop-httpfs related configuration only

directory "/etc/hadoop-httpfs/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

bash "update-hadoop-httpfs-conf-alternatives" do
  code %Q{
   update-alternatives --install /etc/hadoop-httpfs/conf hadoop-httpfs-conf /etc/hadoop-httpfs/conf.#{node.chef_environment} 50
   update-alternatives --set hadoop-httpfs-conf /etc/hadoop-httpfs/conf.#{node.chef_environment}
  }
end

%w{
  httpfs-env.sh
  httpfs-log4j.properties
  httpfs-signature.secret
  httpfs-site.xml
   }.each do |t|
   template "/etc/hadoop-httpfs/conf/#{t}" do
     source "#{t}.erb"
     mode 0644
  end
end