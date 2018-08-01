# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# Cookbook Name:: bcpc-hadoop
# Recipe:: opentsdb
#
# Copyright 2017, Bloomberg Finance L.P.
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
krb_realm = node['bcpc']['hadoop']['kerberos']['realm']
zk_quorum = node['bcpc']['hadoop']['zookeeper']['servers'].map { |s| s[:hostname] + ":#{node['bcpc']['hadoop']['zookeeper']['port']}" }.join(',')

# Overrides for OpenTSDB
node.force_default['bach_opentsdb']['package_version'] =
  node['bach']['repository']['opentsdb']['version']
node.force_default['bach_opentsdb']['java_home'] =
  node['bcpc']['hadoop']['java']
node.force_default['bach_opentsdb']['zk_quorum'] = zk_quorum
node.force_default['bach_opentsdb']['keytab_dir'] =
  node['bcpc']['hadoop']['kerberos']['keytab']['dir']
node.force_default['bach_opentsdb']['hbase_keytab'] =
  node['bcpc']['hadoop']['kerberos']['data']['hbase']['keytab']
node.force_default['bach_opentsdb']['hbase_master_princ'] =
  "hbase/_HOST@#{krb_realm}"
node.force_default['bach_opentsdb']['hbase_region_princ'] =
  "hbase/_HOST@#{krb_realm}"

include_recipe 'bach_opentsdb'
