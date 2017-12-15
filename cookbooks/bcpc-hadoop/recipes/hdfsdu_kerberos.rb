node.default['bcpc']['hadoop']['kerberos']['data'] = \
  node['bcpc']['hadoop']['kerberos']['data'].to_h.update(
    {
      hdfsdu: {
        principal: 'hdfsdu',
        keytab: 'hdfsdu.service.keytab',
        owner: 'hdfsdu',
        group: 'hadoop',
        princhost: '_HOST',
        perms: '0440'
      }
    }
  )
