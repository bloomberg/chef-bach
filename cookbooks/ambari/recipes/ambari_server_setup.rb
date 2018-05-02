# frozen_string_literal: true
# Cookbook Name:: ambari
# Recipe:: ambari_server_setup
# Copyright 2018, Bloomberg Finance L.P.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# /etc/ambari-server/conf/ambari.properties
template 'Create ambari properties file' do
  path File.join(node['ambari']['ambari_server_conf_dir'], 'ambari.properties')
  source 'ambari.properties.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# /etc/ambari-server/conf/password.dat
template File.join(node['ambari']['ambari_server_conf_dir'],
                   'password.dat') do
  source 'password.dat.erb'
  owner 'root'
  group 'root'
  mode '0710'
  sensitive true
end

# /etc/ambari-server/conf/krb5JAASLogin.conf
if node['ambari']['kerberos']['enabled']
  template File.join(
    node['ambari']['ambari_server_conf_dir'],
    'krb5JAASLogin.conf'
  ) do
    source 'krb5JAASLogin.conf.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(lazy {{ ambari_principal: node['ambari']['kerberos']['principal'] }})
  end
end

service 'ambari-server' do
  supports status: true, restart: true
  action [:enable, :start]
  subscribes :restart, 'template[Create ambari properties file]', :immediately
end

ruby_block 'update_default_ambari_admin_password' do
  block do
    update_default_ambari_admin_password
  end
end
