# Cookbook Name : bcpc-hadoop
# Recipe Name : hue_config
# Description : To setup hue configuration only.

make_config('mysql-hue-password', secure_password)
make_config('hue-session-key', secure_password)

directory "/etc/hue/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

bash "update-hue-conf-alternatives" do
  code %Q{
   update-alternatives --install /etc/hue/conf hue-conf /etc/hue/conf.#{node.chef_environment} 50
   update-alternatives --set hue-conf /etc/hue/conf.#{node.chef_environment}
  }
end

template "/etc/hue/conf/hue.ini" do
  source "hue_hue.ini.erb"
  mode 0644
  variables(
    :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
    :rm_hosts  => node[:bcpc][:hadoop][:rm_hosts],
    :hive_hosts => node[:bcpc][:hadoop][:hive_hosts],
    :oozie_hosts => node[:bcpc][:hadoop][:oozie_hosts],
    :httpfs_hosts => node[:bcpc][:hadoop][:httpfs_hosts],
    :hb_hosts => node[:bcpc][:hadoop][:hb_hosts])
end

template "/etc/hue/conf/log4j.properties" do
  source "hue_log4j.properties.erb"
  mode 0644
end

template "/etc/hue/conf/log.conf" do
  source "hue_log.conf.erb"
  mode 0644
end
