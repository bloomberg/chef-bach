include_recipe 'bcpc-hadoop::hadoop_config'

%w{hadoop-mapreduce-historyserver}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

template "/etc/init.d/hadoop-mapreduce-historyserver" do
  source "hdp_hadoop-mapreduce-historyserver-initd.erb"
  mode 0655
end

template "/etc/hadoop/conf/mapred-env.sh" do
  source "hdp_mapred-env.sh.erb"
  mode 0655
end

bash "create-hdfs-history-dir" do
  code <<-EOH
  hdfs dfs -mkdir -p /mr-history/tmp
  hdfs dfs -chmod -R 1777 /mr-history/tmp
  hdfs dfs -mkdir -p /mr-history/done
  hdfs dfs -chmod -R 1777 /mr-history/done
  hdfs dfs -chown -R mapred:hdfs /mr-history
  hdfs dfs -mkdir -p /app-logs
  hdfs dfs -chmod -R 1777 /app-logs
  hdfs dfs -chown yarn /app-logs
  EOH
  user "hdfs"
  not_if "sudo -u hdfs hadoop dfs -test -d /mr-history"
end

service "hadoop-mapreduce-historyserver" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/mapred-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
end
