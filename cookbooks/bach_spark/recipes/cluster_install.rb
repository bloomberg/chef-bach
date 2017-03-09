spark_pkg_version = node[:spark][:package][:version]
spark_bin_dir = node[:spark][:bin][:dir]
hdfs_url = node['spark']['hdfs_url']

bash "create-hdfs-spark-history-dir" do
  code <<-EOH
  hdfs dfs -mkdir -p #{hdfs_url}/spark-history/
  hdfs dfs -chmod -R 1777 #{hdfs_url}/spark-history/
  hdfs dfs -chown -R hdfs:hdfs #{hdfs_url}/spark-history
  EOH
  user "hdfs"
  not_if "hdfs dfs -test -d #{hdfs_url}/spark-history", :user => 'hdfs'
end

bash "create-hdfs-spark-assembly-jar" do
  code <<-EOH
  hdfs dfs -mkdir -p #{hdfs_url}/apps/spark/#{spark_pkg_version}/
  hdfs dfs -chown -R hdfs:hdfs #{hdfs_url}/apps/spark/#{spark_pkg_version}/
  hdfs dfs -copyFromLocal  #{spark_bin_dir}/lib/spark-assembly-*.jar #{hdfs_url}/apps/spark/#{spark_pkg_version}/spark-assembly.jar
  EOH
  user "hdfs"
  not_if "hdfs dfs -test -f #{hdfs_url}/apps/spark/#{spark_pkg_version}/spark-assembly.jar", :user => 'hdfs'
end
