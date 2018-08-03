# Attributes for LDAP Integration

default['bcpc']['hadoop']['ldap'].tap do |ldap|
  ldap['domain'] = 'BCPC.EXAMPLE.COM'
  ldap['short_domain'] = ldap['domain'].split('.')[0]
  ldap['port'] = 389

  ldap['base_dn'] = 'DC=BCPC,DC=EXAMPLE,DC=COM'
  ldap['roles_dn'] = ['CN=roleacct', 'OU=Groups', ldap['base_dn']].join(',')
  ldap['cluster_acl'] = ['CN=bcpc', 'OU=Clusters', ldap['base_dn']].join(',')
end

default['bcpc']['hadoop']['hdfs']['ldap'].tap do |ldap|
  ldap['integration'] = false
  ldap['user'] = "" # must be fully-qualified LDAP DN
  ldap['password'] =  nil
  ldap['search']['depth'] = 0
  ldap['search']['filter']['user'] = "(&(objectclass=user)(sAMAccountName={0}))"
  ldap['search']['filter']['group'] = "(objectClass=group)"
end

