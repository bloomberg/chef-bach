#
# Cookbook Name:: ambari-views-chef
# Recipe:: default
#


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
      keyserver node['ambari']['repo_keyserver']
      key node['ambari']['repo_key']
    end
else
  raise "Platform #{node['platform']} is not supported"
end

include_recipe 'ambari::ambari_server_install'
