#
# Cookbook Name:: bach_repository
# Recipe:: spark
#
require 'tmpdir'

include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
spark_extract_dir = Dir.mktmpdir
spark_install_dir = '/usr/spark'
spark_pkg_prefix = 'spark'
spark_pkg_version = '2.1.0'
spark_tar_file = "spark-#{spark_pkg_version}-bin-hadoop2.7.tgz"
spark_extracted_file_name = "spark-#{spark_pkg_version}-bin-hadoop2.7"

remote_file "#{bins_dir}/#{spark_tar_file}" do
  source "http://d3kbcqa49mib13.cloudfront.net/#{spark_tar_file}"
  checksum '0834c775f38473f67cb122e0ec21074f800ced50c1ff1b9e37e222a0069dc5c7'
  notifies :run, 'execute[extract_spark_tar]', :immediately
end

execute 'extract_spark_tar' do
  command "tar xvf #{spark_tar_file} -C #{spark_extract_dir}"
  cwd bins_dir
  action :nothing
  notifies :run, 'execute[build_spark_package]', :immediately
end

#
# We deliberately include the version number in the package name,
# because it is possible to install multiple versions side by side.
#
execute 'build_spark_package' do
  cwd "#{spark_extract_dir}/#{spark_extracted_file_name}"
  user 'root'
  group 'root'
  command 'fpm -s dir -t deb ' \
    "--prefix #{spark_install_dir}/#{spark_pkg_version} " \
    "-n #{spark_pkg_prefix}-#{spark_pkg_version} " \
    "-v #{spark_pkg_version} " \
    "--description 'Spark Package with Hadoop 2.7' -p #{bins_dir} *"
  umask 0002
  action :nothing
end

directory spark_extract_dir do
  recursive true
  action :delete
end
