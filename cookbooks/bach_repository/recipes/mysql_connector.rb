#
# Cookbook Name:: bach_repository
# Recipe:: mysql_connector
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/mysql-connector-java-5.1.34.tar.gz" do
  source 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.34.tar.gz'
  user 'root'
  group 'root'
  mode 0444
  checksum 'eb33f5e77bab05b6b27f709da3060302bf1d960fad5ddaaa68c199a72102cc5f'
end
