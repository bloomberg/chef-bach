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

site_xml = node.default[:bcpc][:hadoop][:hbase][:site_xml]
generated_values = {}
# For UGI to be able to work properly, we need to specify float host 
# not _HOST, especially since we do not provide keytabs for non floats
generated_values['phoenix.queryserver.kerberos.principal'] =\
  "#{node[:bcpc][:hadoop][:kerberos][:data][:phoenixqs][:principal]}/" +
  float_host(node['fqdn']) +
  "@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
generated_values['phoenix.queryserver.keytab.file'] =\
  "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{node[:bcpc][:hadoop][:kerberos][:data][:phoenixqs][:keytab]}"
generated_values['phoenix.queryserver.serialization'] = 'JSON'

site_xml.merge!(generated_values)

cookbook_file '/etc/init.d/pqs' do
  source 'etc_initd_pqs.sh'
  mode 0o755
  notifies :restart, 'service[pqs]', :delayed
end

serivce 'pqs' do
  action [:enable, :start]
end
