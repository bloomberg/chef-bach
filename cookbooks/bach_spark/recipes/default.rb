spark_pkg_version = node[:spark][:package][:version]
spark_bin_dir = node[:spark][:bin][:dir]

package "spark" do
  action :install
  version spark_pkg_version
end

template "#{spark_bin_dir}/conf/spark-env.sh" do
  source "spark-env.sh.erb"
  mode 0755
end

link "/usr/spark/current" do
 to "#{spark_bin_dir}"
end
