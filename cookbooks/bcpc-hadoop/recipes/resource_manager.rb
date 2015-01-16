include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::hadoop_config'
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

["", "done", "done_intermediate"].each do |dir|
  bash "create-hdfs-history-dir #{dir}" do
    code "hadoop fs -mkdir /user/history/#{dir} && hadoop fs -chmod 1777 /user/history/#{dir} && hadoop fs -chown yarn:mapred /user/history/#{dir}"
    user "hdfs"
    not_if "sudo -u hdfs hadoop fs -test -d /user/history/#{dir}"
  end
end

bash "create-hdfs-yarn-log" do
  code "hadoop fs -mkdir -p /var/log/hadoop-yarn && hadoop fs -chmod 1777 /var/log/hadoop-yarn && hadoop fs -chown yarn:mapred /var/log/hadoosp-yarn"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /var/log/hadoop-yarn"
end

%w{hadoop-yarn-resourcemanager hadoop-client hadoop-mapreduce}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

template "/etc/hadoop/conf/yarn-env.sh" do
  source "hdp_yarn-env.sh.erb"
  mode 0655
end

template "/etc/init.d/hadoop-yarn-resourcemanager" do
  source "hdp_hadoop-yarn-resourcemanager-initd.erb"
  mode 0655
end

bash "setup-mapreduce-app" do
  code <<-EOH
  hdfs dfs -mkdir -p /hdp/apps/2.2.0.0-2041/mapreduce/
  hdfs dfs -put /usr/hdp/2.2.0.0-2041/hadoop/mapreduce.tar.gz /hdp/apps/2.2.0.0-2041/mapreduce/
  hdfs dfs -chown -R hdfs:hadoop /hdp
  hdfs dfs -chmod -R 555 /hdp/apps/2.2.0.0-2041/mapreduce
  hdfs dfs -chmod -R 444 /hdp/apps/2.2.0.0-2041/mapreduce/mapreduce.tar.gz
  EOH
  user "hdfs"
  not_if "sudo -u hdfs hdfs dfs -test -f /hdp/apps/2.2.0.0-2041/mapreduce/mapreduce.tar.gz" 
  only_if "echo 'test'|sudo -u hdfs hdfs dfs -copyFromLocal - /tmp/mapred-test"
  notifies :run,"bash[delete-temp-file]",:immediately
end

bash "delete-temp-file" do
  code <<-EOH
  hdfs dfs -rm /tmp/mapred-test
  EOH
  user "hdfs"
  action :nothing
end

service "hadoop-yarn-resourcemanager" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
end

bash "reload mapreduce nodes" do
  code "yarn rmadmin -refreshNodes"
  user "mapred"
  action :nothing
  subscribes :run, "template[/etc/hadoop/conf/mapred.exclude]", :delayed
end
