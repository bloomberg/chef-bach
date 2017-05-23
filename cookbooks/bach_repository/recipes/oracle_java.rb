#
# Cookbook Name:: bach_repository
# Recipe:: oracle_java
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

# Set the oracle cookie to indicate we have accepted the license agreement.
ruby_block 'oracle-cookie-create' do
  block do
    require 'chef/rest'

    Chef::REST::CookieJar.instance['download.oracle.com:80'] =
      'oraclelicense=accept-securebackup-cookie'
  end
end

remote_file "#{bins_dir}/jce_policy-8.zip" do
  source 'http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip'
  user 'root'
  group 'root'
  mode 0444
  checksum 'f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59'
end

remote_file "#{bins_dir}/jdk-8u131-linux-x64.tar.gz" do
  source 'http://download.oracle.com/otn-pub/java/jdk/' \
    '8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz'
  user 'root'
  group 'root'
  mode 0444
  checksum '62b215bdfb48bace523723cdbb2157c665e6a25429c73828a32f00e587301236'
end
