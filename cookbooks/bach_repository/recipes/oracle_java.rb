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

remote_file "#{bins_dir}/jdk-8u101-linux-x64.tar.gz" do
  source 'http://download.oracle.com/otn-pub/java/jdk/8u101-b13/' \
    'jdk-8u101-linux-x64.tar.gz'
  user 'root'
  group 'root'
  mode 0444
  checksum '467f323ba38df2b87311a7818bcbf60fe0feb2139c455dfa0e08ba7ed8581328'
end
