spark_tar_file = "#{node[:spark][:download][:file][:name]}.#{node[:spark][:download][:file][:type]}"
spark_file_name = node[:spark][:download][:file][:name]
spark_tar_url = node[:spark][:download][:url]
spark_download_dir = node[:spark][:download][:dir]
spark_install_dir = node[:spark][:package][:base]
spark_pkg_prefix = node[:spark][:package][:prefix]
spark_pkg_version = node[:spark][:package][:version]
spark_extract_dir = "/tmp"

gem_package "fpm" do
   action :install
end

package "equivs" do
    action :install
end

remote_file "#{spark_download_dir}/#{spark_tar_file}" do
  source "#{spark_tar_url}/#{spark_tar_file}"
  not_if { File.exists?("#{spark_download_dir}/#{spark_tar_file}") || File.exists?("#{spark_download_dir}/#{spark_pkg_prefix}_#{spark_pkg_version}_amd64.deb") }
end

execute "extract spark tar" do
  command "tar xvf #{spark_tar_file} -C #{spark_extract_dir}"
  cwd spark_download_dir
end

bash "build_spark_package" do
  cwd "#{spark_extract_dir}/#{spark_file_name}"
  user 'root'
  group 'root'
  code %Q{
    fpm -s dir -t deb --prefix #{spark_install_dir}/#{spark_pkg_version} -n "#{spark_pkg_prefix}-#{spark_pkg_version}" -v #{spark_pkg_version} --description "Spark Package with Hadoop" -p #{spark_download_dir} *
  }
  umask 0002
  not_if { File.exists?("#{spark_download_dir}/#{spark_pkg_prefix}-#{spark_pkg_version}_#{spark_pkg_version}_amd64.deb") } 
  notifies :run, "bash[build_bins]", :delayed
end

if node[:spark][:package][:install_meta] == true then
  template "/home/vagrant/chef-bcpc/bins/spark-metapkg" do
  source "spark-metapackage.erb"
  variables(
    :meta_version => spark_pkg_version,
    :package_name => "#{spark_pkg_prefix}-#{spark_pkg_version}",
    :package_version => spark_pkg_version
  )
  end

  bash "equivs-build" do
    cwd "/home/vagrant/chef-bcpc/bins"
    code "equivs-build /home/vagrant/chef-bcpc/bins/spark-metapkg"
    not_if { File.exists?("#{spark_download_dir}/#{spark_pkg_prefix}_#{spark_pkg_version}_amd64.deb") } 
    notifies :run, "bash[build_bins]", :delayed
  end
end

# Call build_bins.sh so the package is added to the apt-repo
bash "build_bins" do
  action :nothing
  user 'root'
  cwd '/home/vagrant/chef-bcpc'
  code "./build_bins.sh"
  umask 0002
end

execute "cleanup extracted tar" do
  command "rm -rf #{spark_extract_dir}/#{spark_file_name}"
end
