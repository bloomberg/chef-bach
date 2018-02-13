
# FILES
namenodes = get_namenodes.select{ |nn| nn[:bcpc][:node_number] }.map{ |nn| "namenode#{nn[:bcpc][:node_number]}" }.join(',')

namenodes_fqdn = get_namenodes.map { |nn| float_host(nn[:fqdn]) }

node.default['bach_ambari']['webhdfs.ha.namenode.http-address.nn1'] = "#{namenodes_fqdn[0]}:#{node['bcpc']['hadoop']['namenode']['http']['port']}"
node.default['bach_ambari']['webhdfs.ha.namenode.https-address.nn1'] = "#{namenodes_fqdn[0]}:#{node['bcpc']['hadoop']['namenode']['https']['port']}"
node.default['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1'] = "#{namenodes_fqdn[0]}:#{node['bcpc']['hadoop']['namenode']['rpc']['port']}"

if node[:bcpc][:hadoop][:hdfs][:HA]
   node.default['bach_ambari']['webhdfs.ha.namenode.http-address.nn2'] = "#{namenodes_fqdn[1]}:#{node['bcpc']['hadoop']['namenode']['http']['port']}"
   node.default['bach_ambari']['webhdfs.ha.namenode.https-address.nn2'] = "#{namenodes_fqdn[1]}:#{node['bcpc']['hadoop']['namenode']['https']['port']}"
   node.default['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2'] = "#{namenodes_fqdn[1]}:#{node['bcpc']['hadoop']['namenode']['rpc']['port']}"
end

node.default['bach_ambari']['webhdfs.ha.namenodes.list'] = "#{namenodes}"
node.default['bach_ambari']['webhdfs.nameservices'] = node.chef_environment
node.default['bach_ambari']['webhdfs.url'] = "webhdfs://#{node.chef_environment}"

node.default['bach_ambari']['proxyuser'] = 'ambari'

if node[:bcpc][:hadoop][:kerberos][:enable]
   node.default['bach_ambari']['webhdfs.auth'] = "auth=KERBEROS;proxyuser=#{node['bach_ambari']['proxyuser']}"
   node.default['bach_ambari']['kerberos']['enabled'] = true
   node.default['bach_ambari']['kerberos']['principal'] = "#{node['bach_ambari']['proxyuser']}/#{float_host(node[:fqdn])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
end
