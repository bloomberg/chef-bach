# frozen_string_literal: true
if node['ambari']['ambari.ldap.isConfigured']
  pwd_file = node['ambari']['ldap']['password_file']
  grp_file = node['ambari']['ldap']['groups_file']
  cfg_dir = node['ambari']['ambari_server_conf_dir']
  groupsfile = File.join(cfg_dir, grp_file)
  passwordfile = File.join(cfg_dir, pwd_file)
  ldap_pwd = node['ambari']['ldap_password']

  file passwordfile do
    content ldap_pwd
    mode '0444'
    sensitive true
  end

  file groupsfile do
    content node['ambari']['ldap']['groups_to_sync']
    mode '0444'
    sensitive true
    notifies :run, 'execute[SyncLdapData]', :delayed
  end

  execute 'SyncLdapData' do
    command 'ambari-server sync-ldap --ldap-sync-admin-name=' \
      "#{node['ambari']['admin']['user']}" \
      "--ldap-sync-admin-password=#{node['ambari']['admin']['password']}" \
      "--groups #{groupsfile}"
    action :nothing
  end
end
