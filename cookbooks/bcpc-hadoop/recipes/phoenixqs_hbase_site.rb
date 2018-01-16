# vim: tabstop=2:shiftwidth=2:softtabstop=2

include_recipe 'bcpc-hadoop::phoenixqs_kerberos'

site_xml = node.default[:bcpc][:hadoop][:hbase][:site_xml]
generated_values = {}
generated_values['phoenix.queryserver.kerberos.principal'] =\
  node['bcpc']['hadoop']['phoenix']['phoenixqs']['principal'] 
generated_values['phoenix.queryserver.keytab.file'] =\
  node['bcpc']['hadoop']['phoenix']['phoenixqs']['keytab']
generated_values['phoenix.queryserver.serialization'] =\
  node['bcpc']['hadoop']['phoenix']['phoenixqs']['serialization']
generated_values['phoenix.queryserver.dns.interface'] =\
   node['bcpc']['networks'][node[:bcpc][:management][:subnet]]['floating']['interface']

site_xml.merge!(generated_values)
