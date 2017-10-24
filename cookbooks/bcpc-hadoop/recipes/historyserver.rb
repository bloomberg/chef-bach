include_recipe 'bcpc-hadoop::hadoop_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

%w{hadoop-mapreduce-historyserver}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
    action :install
  end

  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

#
# The following resource is to fix incorrect permissions set in 
# existing /user/history directory
#
bash "set-correct-user-history-dir-permission" do
  code <<-EOH
  hdfs dfs -chmod -R 0770 /user/history
  hdfs dfs -chmod 1777 /user/history
  hdfs dfs -chmod 1777 /user/history/done
  hdfs dfs -chmod 1777 /user/history/done_intermediate
  EOH
  user "hdfs"
  only_if "hdfs dfs -test -d /user/history && hdfs dfs -ls /user/history/done_intermediate|grep drwxrwxrwt", :user => "hdfs"
end

["", "done", "done_intermediate"].each do |dir|
  bash "create-hdfs-history-dir #{dir}" do
    code "hdfs dfs -mkdir /user/history/#{dir} && hdfs dfs -chmod 1777 /user/history/#{dir} && hdfs dfs -chown yarn:mapred /user/history/#{dir}"
    user "hdfs"
    not_if "hdfs dfs -test -d /user/history/#{dir}", :user => "hdfs"
  end
end

configure_kerberos 'historyserver_spnego' do
  service_name 'spnego'
end

configure_kerberos 'historyserver_kerb' do
  service_name 'historyserver'
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
  subscribes :restart, "log[jdk-version-changed]", :delayed
end
