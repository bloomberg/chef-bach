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

site_xml.merge!(generated_values)
