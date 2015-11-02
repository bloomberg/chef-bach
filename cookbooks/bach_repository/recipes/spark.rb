#
# Cookbook Name:: bach_repository
# Recipe:: spark
#
require 'tmpdir'

include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
spark_extract_dir = Dir.mktmpdir
spark_install_dir = "/usr/spark"
spark_pkg_prefix = "spark"
spark_pkg_version = "1.4.1"
spark_tar_file = "spark-#{spark_pkg_version}-bin-hadoop2.6.tgz"
spark_extracted_file_name = "spark-#{spark_pkg_version}-bin-hadoop2.6"
spark_deb_path =
  "#{bins_dir}/#{spark_pkg_prefix}_#{spark_pkg_version}_amd64.deb"

remote_file "#{bins_dir}/#{spark_tar_file}" do
  source "http://d3kbcqa49mib13.cloudfront.net/#{spark_tar_file}"
  checksum '9cde95349cccfeb99643d2dadb63f8e88ac355e0038aae7d5029142ce94ae370'
end

execute "extract spark tar" do
  command "tar xvf #{spark_tar_file} -C #{spark_extract_dir}"
  cwd bins_dir
  not_if { File.exists?(spark_deb_path) }
end

bash "build_spark_package" do
  cwd "#{spark_extract_dir}/#{spark_extracted_file_name}"
  user 'root'
  group 'root'
  code("fpm -s dir -t deb \ " +
       "--prefix #{spark_install_dir}/#{spark_pkg_version} \ " +
       "-n #{spark_pkg_prefix} -v #{spark_pkg_version} \ " +
       "--description \"Spark Package with Hadoop 2.6\" -p #{bins_dir} *")
  umask 0002
  creates spark_deb_path
end

directory spark_extract_dir do
  recursive true
  action :delete
end
