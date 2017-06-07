# vim: tabstop=2:shiftwidth=2:softtabstop=2
# Cookbook Name : bcpc-hadoop
# Recipe Name : hbase_config
# Description : To setup habse related configuration only

directory "/etc/hbase/conf.#{node.chef_environment}" do
  owner 'root'
  group 'root'
  mode 0o755
  action :create
  recursive true
end

bash 'update-hbase-conf-alternatives' do
  code(%(
    update-alternatives --install /etc/hbase/conf hbase-conf /etc/hbase/conf.#{node.chef_environment} 50
    update-alternatives --set hbase-conf /etc/hbase/conf.#{node.chef_environment}
  ))
end

template '/etc/hbase/conf/hadoop-metrics2-hbase.properties' do
  source 'hb_hadoop-metrics2-hbase.properties.erb'
  mode 0o644
end

# thse are rendered as is
%w(
  log4j.properties
  hbase-policy.xml
).each do |t|
  template "/etc/hbase/conf/#{t}" do
    source "hb_#{t}.erb"
    mode 0o644
  end
end

# thse are rendered as is
%w(
  hbase-client.jaas
  hbase-server.jaas
  regionserver.jaas
).each do |t|
  template "/etc/hbase/conf/#{t}" do
    source "hb_#{t}.erb"
    mode 0o644
    only_if { node['bcpc']['hadoop']['kerberos']['enable'] }
  end
end

subnet = node['bcpc']['management']['subnet']

#
# Add common hbase-site.xml properties
#
generated_values = {
  'hbase.zookeeper.quorum' =>
    node['bcpc']['hadoop']['zookeeper']['servers'].map { |s| float_host(s['hostname']) }.join(','),
  'hbase.zookeeper.property.clientPort' => node['bcpc']['hadoop']['zookeeper']['port'].to_s,
  'hbase.master.hostname' => float_host(node['fqdn']),
  'hbase.regionserver.hostname' => float_host(node['fqdn']),
  'hbase.regionserver.dns.interface' =>
      node['bcpc']['networks'][subnet]['floating']['interface'],
  'hbase.master.dns.interface' =>
      node['bcpc']['networks'][subnet]['floating']['interface'],
  'dfs.client.read.shortcircuit' => node['bcpc']['hadoop']['hbase']['shortcircuit']['read'].to_s
}

# this configuration parameter only belongs in master
if node.roles.include? 'BCPC-Hadoop-Head-HBase'
  generated_values['hbase.master.wait.on.regionservers.mintostart'] =
    (node['bcpc']['hadoop']['rs_hosts'].length / 2 + 1).to_s
end

#
# Any hbase-site.xml property related to Kerberos need to go here
#
if node['bcpc']['hadoop']['kerberos']['enable'] == true
  generated_values['hbase.security.authorization'] = 'true'
  generated_values['hbase.superuser'] = node['bcpc']['hadoop']['hbase']['superusers'].join(',')
  generated_values['hbase.coprocessor.region.classes'] =
    'org.apache.hadoop.hbase.security.token.TokenProvider,' \
    'org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint,' \
    'org.apache.hadoop.hbase.security.access.AccessController'
  generated_values['hbase.security.exec.permission.checks'] = 'true'
  generated_values['hbase.coprocessor.regionserver.classes'] =
    'org.apache.hadoop.hbase.security.access.AccessController'
  generated_values['hbase.coprocessor.master.classes'] =
    'org.apache.hadoop.hbase.security.access.AccessController'
  generated_values['hbase.security.authentication'] = 'kerberos'
  generated_values['hbase.master.kerberos.principal'] =
    "#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['principal']}/" \
    "#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['princhost'] == '_HOST' ? '_HOST' : node['bcpc']['hadoop']['kerberos']['data']['hbase']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  generated_values['hbase.master.keytab.file'] =
    "#{node['bcpc']['hadoop']['kerberos']['keytab']['dir']}/#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['keytab']}"
  generated_values['hbase.regionserver.kerberos.principal'] =
    "#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['principal']}/#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['princhost'] == '_HOST' ? '_HOST' : node['bcpc']['hadoop']['kerberos']['data']['hbase']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  generated_values['hbase.regionserver.keytab.file'] =
    "#{node['bcpc']['hadoop']['kerberos']['keytab']['dir']}/#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['keytab']}"
  generated_values['phoenix.queryserver.kerberos.principal'] =
    "#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['principal']}/#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['princhost'] == '_HOST' ? '_HOST' : node['bcpc']['hadoop']['kerberos']['data']['hbase']['princhost']}@#{node['bcpc']['hadoop']['kerberos']['realm']}"
  generated_values['phoenix.queryserver.keytab.file'] =
    "#{node['bcpc']['hadoop']['kerberos']['keytab']['dir']}/#{node['bcpc']['hadoop']['kerberos']['data']['hbase']['keytab']}"
  generated_values['hbase.rpc.engine'] = 'org.apache.hadoop.hbase.ipc.SecureRpcEngine'
end

#
# If HDFS short circuit read is enabled properties in this section will be added to hbase-site.xml
#
if node['bcpc']['hadoop']['hbase']['shortcircuit']['read'] == true
  generated_values['dfs.domain.socket.path'] =  '/var/run/hadoop-hdfs/dn._PORT'
  generated_values['dfs.client.read.shortcircuit.buffer.size'] =
    node['bcpc']['hadoop']['hbase']['dfs']['client']['read']['shortcircuit']['buffer']['size'].to_s
end

#
# If HBASE bucket cache is enabled the properties from this section will be included in hbase-site.xml
#
bucketcache_size = (node['bcpc']['hadoop']['hbase_rs']['mx_dir_mem']['size'] - node['bcpc']['hadoop']['hbase_rs']['hdfs_dir_mem']['size']).floor
if node['bcpc']['hadoop']['hbase']['bucketcache']['enabled'] == true
  generated_values['hbase.regionserver.global.memstore.upperLimit'] = node['bcpc']['hadoop']['hbase_rs']['memstore']['upperlimit'].to_s
  generated_values['hfile.block.cache.size'] = node['bcpc']['hadoop']['hbase']['blockcache']['size'].to_s
  generated_values['hbase.bucketcache.size'] = bucketcache_size
  generated_values['hbase.bucketcache.ioengine '] = node['bcpc']['hadoop']['hbase']['bucketcache']['ioengine']
  generated_values['hbase.bucketcache.combinedcache.enabled'] = true
end

#
# if HBASE region replication is enabled the properties in this section will be included in hbase-site.xml
#
if node['bcpc']['hadoop']['hbase']['region']['replication']['enabled'] == true
  # server side
  generated_values['hbase.region.replica.replication.enabled']                   = node['bcpc']['hadoop']['hbase']['region']['replication']['enabled']
  generated_values['hbase.region.replica.storefile.refresh.memstore.multiplier'] = node['bcpc']['hadoop']['hbase']['region']['replica']['storefile']['refresh']['memstore']['multiplier']
  generated_values['hbase.region.replica.wait.for.primary.flush']                = node['bcpc']['hadoop']['hbase']['region']['replica']['wait']['for']['primary']['flush']
  generated_values['hbase.hregion.memstore.block.multiplier']                    = node['bcpc']['hadoop']['hbase']['hregion']['memstore']['block']['multiplier']
  generated_values['hbase.meta.replica.count']                                   = node['bcpc']['hadoop']['hbase']['meta']['replica']['count']
  generated_values['hbase.master.hfilecleaner.ttl']                              = node['bcpc']['hadoop']['hbase_master']['hfilecleaner']['ttl']
  generated_values['hbase.master.loadbalancer.class']                            = node['bcpc']['hadoop']['hbase_master']['loadbalancer']['class']
  generated_values['hbase.regionserver.storefile.refresh.all']                   = node['bcpc']['hadoop']['hbase_rs']['storefile']['refresh']['all']
  generated_values['hbase.regionserver.storefile.refresh.period']                = node['bcpc']['hadoop']['hbase_rs']['storefile']['refresh']['period']
  generated_values['hbase.regionserver.global.memstore.lowerLimit']              = node['bcpc']['hadoop']['hbase_rs']['memstore']['lowerlimit']
  generated_values['hbase.regionserver.meta.storefile.refresh.period']           = node['bcpc']['hadoop']['hbase_rs']['meta']['storefile']['refresh']['period']

  # client side
  generated_values['hbase.ipc.client.specificThreadForWriting']                  = node['bcpc']['hadoop']['hbase']['ipc']['client']['specificthreadforwriting']
  generated_values['hbase.client.primaryCallTimeout.get']                        = node['bcpc']['hadoop']['hbase']['client']['primarycalltimeout']['get']
  generated_values['hbase.client.primaryCallTimeout.multiget']                   = node['bcpc']['hadoop']['hbase']['client']['primarycalltimeout']['multiget']
  generated_values['hbase.client.primaryCallTimeout.scan']                       = node['bcpc']['hadoop']['hbase']['client']['primarycalltimeout']['scan']
  generated_values['hbase.client.pause']                                         = node['bcpc']['hadoop']['hbase']['client']['pause']
  generated_values['hbase.client.retries.number']                                = node['bcpc']['hadoop']['hbase']['client']['retries']['number']
  generated_values['hbase.meta.replicas.use']                                    = node['bcpc']['hadoop']['hbase']['meta']['replicas']['use']
end

site_xml = node['bcpc']['hadoop']['hbase']['site_xml']
complete_hbase_site_hash = generated_values.merge(site_xml)

template '/etc/hbase/conf/hbase-site.xml' do
  source 'generic_site.xml.erb'
  mode 0o644
  variables(options: complete_hbase_site_hash)
end

template '/etc/hbase/conf/regionservers' do
  source 'hb_regionservers.erb'
  mode 0o644
  variables(rs_hosts: node['bcpc']['hadoop']['rs_hosts'])
end

include_recipe 'bcpc-hadoop::hbase_env'
