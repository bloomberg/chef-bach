node.default['bcpc']['hadoop']['kerberos']['data']\
  ['hbase_policy_enforcer'].tap do |hbase|
    hbase['principal'] = 'hbase_policy_enforcer'
    hbase['keytab'] = 'hbase_policy_enforcer.service.keytab'
    hbase['owner'] = 'hbase_policy_enforcer'
    hbase['princhost'] = '_HOST'
    hbase['perms'] = '0440'
  end
