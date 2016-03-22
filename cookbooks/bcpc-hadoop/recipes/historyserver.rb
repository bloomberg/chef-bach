include_recipe 'bcpc-hadoop::hadoop_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

%w{hadoop-mapreduce-historyserver}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
    action :install
  end

  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

template "/etc/hadoop/conf/mapred-env.sh" do
  source "hdp_mapred-env.sh.erb"
  mode 0655
end

bash "create-hdfs-history-dir" do
  code <<-EOH
  hdfs dfs -mkdir -p /var/log/hadoop-yarn/apps
  hdfs dfs -chmod -R 1777 /var/log/hadoop-yarn/apps
  EOH
  user "hdfs"
  not_if "hdfs dfs -test -d /var/log/hadoop-yarn/apps", :user => "hdfs"
end

link "/etc/init.d/hadoop-mapreduce-historyserver" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-mapreduce/etc/init.d/hadoop-mapreduce-historyserver"
  notifies :run, 'bash[kill mapred-historyserver]', :immediate
end

bash "kill mapred-historyserver" do
  code "pkill -u mapred -f historyserver"
  action :nothing
  returns [0, 1]
end

service "hadoop-mapreduce-historyserver" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "link[/etc/init.d/hadoop-mapreduce-historyserver]", :immediate
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/mapred-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
end
