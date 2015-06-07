include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::httpfs_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

package hwx_pkg_str("hadoop-httpfs", node[:bcpc][:hadoop][:distribution][:release]) do
  action :install
end

hdp_select('hadoop-httpfs', node[:bcpc][:hadoop][:distribution][:active_release])

link "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-httpfs/conf" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/etc/hadoop-httpfs/tomcat-deployment.dist/conf"
end

link '/etc/init.d/hadoop-httpfs' do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-httpfs/etc/init.d/hadoop-httpfs"
  notifies :run, 'bash[kill hdfs-httpfs]', :immediate
end

bash "kill hdfs-httpfs" do
  code "pkill -u hdfs -f httpfs"
  action :nothing
  returns [0, 1]
end

service "hadoop-httpfs" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop-httpfs/conf/httpfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "bash[hdp-select hadoop-httpfs]", :delayed
  subscribes :restart, "link[/etc/init.d/hadoop-httpfs]", :immediate
end
