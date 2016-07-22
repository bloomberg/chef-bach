include_recipe 'bcpc-hadoop::hadoop_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/yarn/local" do
    owner "yarn"
    group "yarn"
    mode 0755
    action :create
    recursive true
  end

  directory "/disk/#{i}/yarn/logs" do
    owner "yarn"
    group "yarn"
    mode 0755
    action :create
    recursive true
  end
end

bash "create-hdfs-yarn-log" do
  code "hdfs dfs -mkdir -p /var/log/hadoop-yarn && hdfs dfs -chmod 0777 /var/log/hadoop-yarn && hdfs dfs -chown yarn:mapred /var/log/hadoop-yarn"
  user "hdfs"
  not_if "hdfs dfs -test -d /var/log/hadoop-yarn", :user => "hdfs"
end

# list hdp packages to install
%w{hadoop-yarn-resourcemanager hadoop-client hadoop-mapreduce-historyserver}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
    action :install
  end

  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

link "/etc/init.d/hadoop-yarn-resourcemanager" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-yarn/etc/init.d/hadoop-yarn-resourcemanager"
  notifies :run, 'bash[kill yarn-resourcemanager]', :immediate
end

file "/etc/hadoop/conf/yarn.exclude" do
  content node["bcpc"]["hadoop"]["decommission"]["hosts"].join("\n")
  mode 0644
  owner 'yarn'
  group 'hdfs'
  only_if { !node["bcpc"]["hadoop"]["decommission"]["hosts"].nil? }
end

bash "kill yarn-resourcemanager" do
  code "pkill -u yarn -f resourcemanager"
  action :nothing
  returns [0, 1]
end

configure_kerberos 'rm_kerb' do
  service_name 'resourcemanager'
end

hdfs_write = "echo 'test' | hdfs dfs -copyFromLocal - /user/hdfs/chef-mapred-test"
hdfs_remove = "hdfs dfs -rm -skipTrash /user/hdfs/chef-mapred-test"

bash "setup-mapreduce-app" do
  code <<-EOH
  hdfs dfs -mkdir -p /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/mapreduce/
  hdfs dfs -put /usr/hdp/#{node[:bcpc][:hadoop][:distribution][:release]}/hadoop/mapreduce.tar.gz /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/mapreduce/
  hdfs dfs -chown -R hdfs:hadoop /hdp
  hdfs dfs -chmod -R 555 /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/mapreduce
  hdfs dfs -chmod -R 444 /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/mapreduce/mapreduce.tar.gz
  EOH
  user "hdfs"
  not_if "hdfs dfs -test -f /hdp/apps/#{node[:bcpc][:hadoop][:distribution][:release]}/mapreduce/mapreduce.tar.gz", :user => "hdfs" 
  only_if "#{hdfs_write} && #{hdfs_remove}", :user => "hdfs"
end

bash "delete-temp-file" do
  code <<-EOH
  hdfs dfs -rm /user/hdfs/chef-mapred-test
  EOH
  user "hdfs"
  action :nothing
end

service "hadoop-yarn-resourcemanager" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/mapred-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "bash[hdp-select hadoop-yarn-resourcemanager]", :delayed
end

bash "reload mapreduce nodes" do
  code "yarn rmadmin -refreshNodes"
  user "mapred"
  action :nothing
  subscribes :run, "template[/etc/hadoop/conf/yarn.exclude]", :delayed
end
