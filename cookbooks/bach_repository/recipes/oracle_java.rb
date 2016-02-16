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

remote_file "#{bins_dir}/UnlimitedJCEPolicyJDK7.zip" do
  source 'http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip'
  user 'root'
  group 'root'
  mode 0444
  checksum '7a8d790e7bd9c2f82a83baddfae765797a4a56ea603c9150c87b7cdb7800194d'
end

remote_file "#{bins_dir}/jce_policy-8.zip" do
  source 'http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip'
  user 'root'
  group 'root'
  mode 0444
  checksum 'f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59'
end

remote_file "#{bins_dir}/jdk-7u51-linux-x64.tar.gz" do
  source 'http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.tar.gz'
  user 'root'
  group 'root'
  mode 0444
  checksum '77367c3ef36e0930bf3089fb41824f4b8cf55dcc8f43cce0868f7687a474f55c'
end
