#
# Cookbook:: bach_ambari_wrapper
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

user "#{node['bach_ambari']['proxyuser']}" do
  comment 'ambari user is created to download ambari keytab'
end

configure_kerberos 'ambari_kerb' do
  service_name 'ambari'
end

include_recipe 'bach_ambari::default'
