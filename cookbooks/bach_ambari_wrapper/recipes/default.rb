#
# Cookbook:: bach_ambari_wrapper
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

mysql_hosts = node['bcpc']['hadoop']['mysql_hosts'].map { |m| m[:hostname] }
node.default['bach_ambari']['databasehost'] = mysql_hosts

configure_kerberos 'ambari_kerb' do
  service_name 'ambari'
end

include_recipe 'bach_ambari::default'
