#
# Cookbook Name:: bcpc-hadoop
# Recipe:: oozie_config
#
# Copyright 2014, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This recipe populates data bags and creates config files for Oozie
#

unless get_config('oozie-keystore-password')
  make_config('oozie-keystore-password', secure_password)
end

directory "/etc/oozie/conf.#{node.chef_environment}" do
  owner 'root'
  group 'root'
  mode 0755
  action :create
  recursive true
end

bash 'update-oozie-conf-alternatives' do
  code('update-alternatives --install /etc/oozie/conf oozie-conf ' \
        "/etc/oozie/conf.#{node.chef_environment} 50; " \
        'update-alternatives --set oozie-conf ' \
        "/etc/oozie/conf.#{node.chef_environment}")
end

#
# Set up oozie config files
#
%w(
  oozie-env.sh
  oozie-site.xml
  adminusers.txt
  oozie-log4j.properties
).each do |t|
  template "/etc/oozie/conf/#{t}" do
    source "ooz_#{t}.erb"
    mode 0644
    variables(mysql_hosts:
               node[:bcpc][:hadoop][:mysql_hosts].map { |m| m[:hostname] },
              mysql_username: mysql_local_connection_info('oozie')[:username],
              mysql_password: mysql_local_connection_info('oozie')[:password],
              zk_hosts: node[:bcpc][:hadoop][:zookeeper][:servers],
              ooz_hosts: node[:bcpc][:hadoop][:oozie_hosts],
              hive_hosts: node[:bcpc][:hadoop][:hive_hosts])
  end
end
