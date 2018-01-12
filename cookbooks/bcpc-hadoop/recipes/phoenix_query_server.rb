# vim: tabstop=2:shiftwidth=2:softtabstop=2

include_recipe 'bcpc-hadoop::phoenixqs_kerberos'

site_xml = node.default[:bcpc][:hadoop][:hbase][:site_xml]
generated_values = {}
generated_values['phoenix.queryserver.kerberos.principal'] =\
  node['bcpc']['hadoop']['phoenix']['phoenixqs']['principal'] =\
generated_values['phoenix.queryserver.keytab.file'] =\
  "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/" +
  node[:bcpc][:hadoop][:kerberos][:data][:phoenixqs][:keytab]
generated_values['phoenix.queryserver.serialization'] =\
  node['bcpc']['hadoop']['phoenix']['phoenixqs']['serialization']

site_xml.merge!(generated_values)

qs_runas = node['bcpc']['hadoop']['phoenix']['phoenixqs']['username']

user qs_runas do
  comment 'Runs phoenix queryserver'
  only_if { node['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] }
end

group qs_runas do
  members [ qs_runas ] 
  only_if { node['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] }
end

template '/etc/init.d/pqs' do
  source 'etc_initd_pqs.erb'
  variables (qs_runas: qs_runas) 
  mode 0o755
  notifies :restart, 'service[pqs]', :delayed
end

service 'pqs' do
  action [:enable, :start]
end
