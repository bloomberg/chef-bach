#
# Cookbook Name:: bach_repository
# Recipe:: oracle_java
#
require 'pathname'
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

# Set the oracle cookie to indicate we have accepted the license agreement.
ruby_block 'oracle-cookie-create' do
  block do
    require 'chef/rest'

    Chef::REST::CookieJar.instance['edelivery.oracle.com:80'] =
      'oraclelicense=accept-securebackup-cookie'
    Chef::REST::CookieJar.instance['edelivery.oracle.com:443'] =
      'oraclelicense=accept-securebackup-cookie'
    Chef::REST::CookieJar.instance['download.oracle.com:80'] =
      'oraclelicense=accept-securebackup-cookie'
    Chef::REST::CookieJar.instance['download.oracle.com:443'] =
      'oraclelicense=accept-securebackup-cookie'
  end
end

remote_file "#{bins_dir}/jce_policy-8.zip" do
  source node['bach']['repository']['java']['jce_url']
  user 'root'
  group 'root'
  mode 0444
  checksum node['bach']['repository']['java']['jce_checksum']
end

java_tgz_name = Pathname.new(node['bach']['repository']['java']['jdk_url'])\
                        .basename.to_s

jdk_local_path = "#{bins_dir}/#{java_tgz_name}"

remote_file jdk_local_path do
  source node['bach']['repository']['java']['jdk_url']
  user 'root'
  group 'root'
  mode 0444
  checksum node['bach']['repository']['java']['jdk_checksum']
end

ruby_block 'Copy JDK to file cache' do
  block do
    require 'fileutils'
    ::FileUtils.cp(jdk_local_path, Chef::Config[:file_cache_path])
  end
end
