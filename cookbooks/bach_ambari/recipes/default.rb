#
# Cookbook:: bach_ambari
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
# configure ambari-server reposiory and installs ambari server.
include_recipe 'ambari::default'

# creates user, database and database schema for ambari server.
include_recipe 'bach_ambari::mysql_server_external_setup'

# It is required to download ambari kerberos file.
user 'ambari' do
  comment 'ambari user'
end


configure_kerberos 'ambari_kerb' do
  service_name 'ambari'
end

include_recipe 'ambari::ambari_server_setup'
include_recipe 'ambari::ambari_views_setup'

include_recipe 'bach_ambari::remove_sensitive_attributes'
