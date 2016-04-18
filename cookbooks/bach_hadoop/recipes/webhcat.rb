::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

package node['bcpc']['mysql']['connector']['package']['short_name'] do
  action :upgrade
end

link "/usr/lib/hive/lib/mysql.jar" do
  to "/usr/share/java/mysql.jar"
end

%w{hive-hcatalog hive-hcatalog-server hive-webhcat}.each do |p|
  package hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release]) do
    action :upgrade
  end
end
%w{hive-metastore hive-webhcat hive-server2}.each do |comp|
  hdp_select(comp, node[:bcpc][:hadoop][:distribution][:active_release])
end

%w{hive-hcatalog-server}.each do |s|
  service s do
    action [:enable, :start]
    supports :status => true, :restart => true, :reload => false
    subscribes :restart, "template[/etc/webhcat/conf/webhcat-site.xml]", :delayed
    subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
    subscribes :restart, "bash[hdp-select hive-metastore]", :delayed
  end
end
