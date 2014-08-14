include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::httpfs_config'

package "hadoop-httpfs" do
  action :upgrade
end

service "hadoop-httpfs" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop-httpfs/conf/httpfs-site.xml]"
end