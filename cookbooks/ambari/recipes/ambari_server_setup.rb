#
# Cookbook Name:: ambari
# Recipe:: ambari_server_setup
#


# /etc/ambari-server/conf/ambari.properties
template File.join(node['ambari']['ambari_server_conf_dir'],'ambari.properties') do
  source 'ambari.properties.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# /etc/ambari-server/conf/password.dat
template File.join(node['ambari']['ambari_server_conf_dir'],'password.dat') do
  source 'password.dat.erb'
  owner 'root'
  group 'root'
  mode '0710'
  sensitive true
end

# /etc/ambari-server/conf/krb5JAASLogin.conf
if node['ambari']['kerberos']['enabled']
  template File.join(node['ambari']['ambari_server_conf_dir'], 'krb5JAASLogin.conf') do
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
