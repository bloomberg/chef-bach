if node['ambari']['ambari.ldap.isConfigured'] then
  pwd_file=node['ambari']['ldap']['password_file']
  grp_file=node['ambari']['ldap']['groups_file']
  cfg_dir=node['ambari']['ambari_server_conf_dir']
  groupsFile=File.join(cfg_dir, grp_file )
  passwordFile=File.join(cfg_dir, pwd_file)
  ldap_pwd = node['ambari']['ldap_password'] 

  file passwordFile do
    content "#{ldap_pwd}"
    mode 0444
    sensitive true
  end

  file groupsFile do
    content node['ambari']['ldap']['groups_to_sync']
    mode 044
    sensitive true
    notifies :run, "execute[SyncLdapData]", :delayed 
  end

  execute 'SyncLdapData' do
    command "ambari-server sync-ldap --ldap-sync-admin-name=#{node['ambari']['admin']['user']} --ldap-sync-admin-password=#{node['ambari']['admin']['password']} --groups #{groupsFile}"
    action :nothing
  end

end



