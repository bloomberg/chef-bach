node.default['bcpc']['hadoop']['kerberos']['data'] = \
  node['bcpc']['hadoop']['kerberos']['data'].to_h.update(
    {
      ambari: {
          principal: 'ambari',
          keytab: 'ambari.service.keytab',
          owner: 'ambari',
          group: 'root',
          princhost: '_HOST',
          perms: '0440',
          spnego_keytab: 'spnego.service.keytab'
         }
    }
  )
