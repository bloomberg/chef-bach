#
# Cookbook Name:: ambari-views-chef
# Recipe:: default
#
# Copyright (c) 2016 Artem Ervits, All Rights Reserved.

# include_recipe 'ambari::setattr'
# dependencies
%w(openssh-client wget curl unzip tar python2.7 openssl libpq5 ssl-cert mysql-client).each do |pkg|
  package pkg do
  end
end

case node['platform']
when 'ubuntu'
    apt_repository 'ambari' do
      uri node['ambari']['ambari_ubuntu_repo_url']
      components ['main']
      distribution 'Ambari'
      action :add
      keyserver 'keyserver.ubuntu.com'
      key 'B9733A7A07513CAD'
    end
else
  raise "Platform #{node['platform']} is not supported"
end

include_recipe 'ambari::ambari_server_install'
