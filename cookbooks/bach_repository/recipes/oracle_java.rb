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
  source node['java']['oracle']['jce']['8']['url']
  user 'root'
  group 'root'
  mode 0444
  checksum node['java']['oracle']['jce']['8']['checksum']
end

java_tgz_name = Pathname.new(node['java']['jdk']['8']['x86_64']['url'])\
                        .basename.to_s

remote_file 'JDK' do
  path "#{bins_dir}/#{Pathname.new(java_tgz_name).basename.to_s}"
  source node['java']['jdk']['8']['x86_64']['url']
  user 'root'
  group 'root'
  mode 0444
  checksum node['java']['jdk']['8']['x86_64']['checksum']
end
