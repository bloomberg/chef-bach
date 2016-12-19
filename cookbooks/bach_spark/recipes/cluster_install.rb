# vim: tabstop=2:shiftwidth=2:softtabstop=2

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

execute "create spark #{spark_pkg_version} HDFS directory" do
  command "hdfs dfs -mkdir -p #{hdfs_url}/apps/spark/#{spark_pkg_version}"
  user "hdfs"
end

execute "create spark #{spark_pkg_version} archive" do
  command "tar -czvf /tmp/spark_#{spark_pkg_version}_jars.tgz -C #{spark_bin_dir}/jars ."
  user "hdfs"
  not_if "hdfs dfs -test -f #{hdfs_url}/apps/spark/#{spark_pkg_version}/spark_jars.tgz", :user => 'hdfs'
  notifies :run, "execute[upload #{spark_pkg_version} archive to HDFS]", :immediately
end

execute "upload #{spark_pkg_version} archive to HDFS" do
  command "hdfs dfs -copyFromLocal /tmp/spark_#{spark_pkg_version}_jars.tgz #{hdfs_url}/apps/spark/#{spark_pkg_version}/spark_jars.tgz"
  user "hdfs"
  action :nothing
  not_if "hdfs dfs -test -f #{hdfs_url}/apps/spark/#{spark_pkg_version}/spark_jars.tgz", :user => 'hdfs'
  notifies :run, "execute[cleanup /tmp/spark_#{spark_pkg_version}_jars.tgz]", :immediately
end

execute "cleanup /tmp/spark_#{spark_pkg_version}_jars.tgz" do 
  command "rm /tmp/spark_#{spark_pkg_version}_jars.tgz"
  user "hdfs"
  action :nothing
end
