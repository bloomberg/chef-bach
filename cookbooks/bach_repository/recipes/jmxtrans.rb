#
# Cookbook Name:: bach_repository
# Recipe:: jmxtrans
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/jmxtrans-20120525-210643-4e956b1144.zip" do
  source 'http://github.com/downloads/jmxtrans/jmxtrans/jmxtrans-20120525-210643-4e956b1144.zip'
  user 'root'
  group 'root'
  mode 0444
  checksum '0a5a2c361cc666f5a7174e2c77809e1a973c3af62868d407c68beb892f1b0217'
end
