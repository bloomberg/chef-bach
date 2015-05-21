include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::httpfs_config'

package "hadoop-httpfs" do
  action :upgrade
end

link "/usr/hdp/2.2.0.0-2041/hadoop-httpfs/conf" do
  to "/usr/hdp/2.2.0.0-2041/etc/hadoop-httpfs/tomcat-deployment.dist/conf"
end

template "/etc/init.d/hadoop-httpfs" do
  source "hdp_hadoop-httpfs-initd.erb"
  mode 0655
end

service "hadoop-httpfs" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop-httpfs/conf/httpfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
end
