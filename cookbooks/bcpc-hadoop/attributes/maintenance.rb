default[:bcpc][:hadoop][:acl_group] = "acl_group_for_pam"
default[:bcpc][:hadoop][:base_dn] = "DC=bcpc,DC=example,DC=com"
default[:bcpc][:hadoop][:group_ou] = "OU=Groups,#{node[:bcpc][:hadoop][:base_dn]}"
default[:bcpc][:hadoop][:domain] = "bcpc.example.com"
default[:bcpc][:hadoop][:short_domain] = node[:bcpc][:hadoop][:domain].split('.')[0]
default[:bcpc][:hadoop][:dir_threads] = 32
default[:bcpc][:hadoop][:group_dir_mode] = "770"
default[:bcpc][:hadoop][:user_dir_mode] = "755"
default[:bcpc][:hadoop][:group_dir_prohibited_groups] = ['^users$', '^svn.*$', '^git.*$', 'dba']
default[:bcpc][:hadoop][:ldap_query_keytab] = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:namenode][:keytab]}"
