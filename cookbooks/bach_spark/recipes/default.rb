node.default[:bcpc][:hadoop][:yarn][:aux_services][:spark_shuffle][:class] = "org.apache.spark.network.yarn.YarnShuffleService"

spark_pkg_version = node[:spark][:package][:version]
spark_bin_dir = node[:spark][:bin][:dir]
hdfs_url = node['spark']['hdfs_url']

package "spark" do
  action :install
  version spark_pkg_version
end

template "#{spark_bin_dir}/conf/spark-env.sh" do
  source "spark-env.sh.erb"
  mode 0755
end

template "#{spark_bin_dir}/conf/spark-defaults.conf" do
  source "spark-defaults.conf.erb"
  mode 0755
end

link "/#{spark_bin_dir}/lib/spark-yarn-shuffle.jar" do
 to "#{spark_bin_dir}/lib/spark-#{spark_pkg_version}-yarn-shuffle.jar"
end

link "/usr/spark/current" do
 to "#{spark_bin_dir}"
end
