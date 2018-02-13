#
# Cookbook Name:: ambari
# Recipe:: ambari_server_setup
#
# Copyright (c) 2016 Artem Ervits, All Rights Reserved.


# /etc/ambari-server/conf/ambari.properties
template "#{node['ambari']['ambari_server_conf_dir']}ambari.properties" do
  source 'ambari.properties.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# /etc/ambari-server/conf/password.dat
template "#{node['ambari']['ambari_server_conf_dir']}password.dat" do
  source 'password.dat.erb'
  owner 'root'
  group 'root'
  mode '0710'
end

# /etc/ambari-server/conf/krb5JAASLogin.conf
if node['ambari']['kerberos']['enabled']
  template "#{node['ambari']['ambari_server_conf_dir']}krb5JAASLogin.conf" do
    source 'krb5JAASLogin.conf.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end
end

service 'ambari-server' do
  supports :status => true, :restart => true
  action [:enable, :start]
end
