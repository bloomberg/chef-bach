# vim: tabstop=2:shiftwidth=2:softtabstop=2

node.default['bcpc']['hadoop']['kerberos']['data'] = \
  node['bcpc']['hadoop']['kerberos']['data'].to_h.update(
    {
      phoenixqs: {
        principal: 'phoenixqs',
        keytab: 'phoenixqs.service.keytab',
        owner: 'phoenixqs',
        group: 'phoenixqs',
        princhost: '_HOST',
        perms: '0440',
        spnego_keytab: 'phoenixqs.service.keytab'
      }
    }
)

