#
# Cookbook Name:: bach_opentsdb
# Recipe:: default
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Install the OpenTSDB package
package 'opentsdb' do
  version node['bach_opentsdb']['package_version']
end

# Install any dependencies that are missed
pkglist = %w(gnuplot-nox)
pkglist.each do |pkg|
  package pkg
end

# Write the configuration files
conf_dir = node['bach_opentsdb']['config_directory']

template '/etc/default/opentsdb' do
  source 'etc_default_opentsdb.erb'
  mode 0o0644
  user 'root'
  group 'root'
  notifies :restart, 'service[opentsdb]', :delayed
end

template "#{conf_dir}/opentsdb.conf" do
  source 'opentsdb.conf.erb'
  mode 0o0644
  user 'root'
  group 'root'
  notifies :restart, 'service[opentsdb]', :delayed
end

template "#{conf_dir}/logback.xml" do
  source 'logback.xml.erb'
  mode 0o0644
  user 'root'
  group 'root'
  variables(logdir: node['bach_opentsdb']['log_directory'])
  notifies :restart, 'service[opentsdb]', :delayed
end

template node['bach_opentsdb']['jaas_config_file'] do
  source 'opentsdb.jaas.erb'
  mode 0o0644
  user 'root'
  group 'root'
  notifies :restart, 'service[opentsdb]', :delayed
end

template '/etc/init.d/opentsdb' do
  source 'etc_initd_opentsdb.erb'
  mode 0o0755
  user 'root'
  group 'root'
  notifies :restart, 'service[opentsdb]', :delayed
end

template "#{node['bach_opentsdb']['bin_directory']}/tsdb.local" do
  source 'tsdb.local.erb'
  mode 0o0644
  user 'root'
  group 'root'
  notifies :restart, 'service[opentsdb]', :delayed
end

# In case of an older release
link '/usr/share/opentsdb/tsdb.local' do
  to "#{node['bach_opentsdb']['bin_directory']}/tsdb.local"
end

# Fix directory ownership/permissions
fixpermsdirs = [
  node['bach_opentsdb']['http']['cachedir'],
  node['bach_opentsdb']['log_directory']
]

fixpermsdirs.each do |dir|
  directory dir do
    user node['bach_opentsdb']['tsd_user']
    group node['bach_opentsdb']['tsd_group']
    notifies :restart, 'service[opentsdb]', :delayed
  end
end

# Initialize the HBase tables
execute 'create-opentsdb-hbase-tables' do
  command '/usr/share/opentsdb/tools/create_table.sh'
  user 'hbase'
  group 'hbase'
  environment(
    COMPRESSION: 'LZO',
    HBASE_HOME: '/usr/hdp/current/hbase-client'
  )
  not_if 'echo "list" | hbase shell | grep -q "tsdb"'
  notifies :restart, 'service[opentsdb]', :delayed
end

# Manage the service/startup
service 'opentsdb' do
  action [:enable, :start]
end
