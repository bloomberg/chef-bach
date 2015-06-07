#
# Cookbook Name:: bcpc
# Recipe:: test_mysql_connector
#
# Copyright (C) 2015 Bloomberg Finance L.P.
#

package 'libmysql-java' do
  provider Chef::Provider::Package::Dpkg
  source "#{node['bcpc']['bin_dir']['path']}/#{node['bcpc']['mysql']['connector']['package']['name']}"
end

bash 'build_bins' do
  code '/bin/true'
  action :nothing
end
