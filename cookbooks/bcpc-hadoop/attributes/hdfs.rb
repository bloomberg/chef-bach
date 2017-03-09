# vim: tabstop=2:shiftwidth=2:softtabstop=2 
# Setting balancer andwidth to default value as per hdfs-default.xml
default["hadoop"]["hdfs"]["balancer"]["bandwidth"] = 1048576
# balancer thread multiplier constant
default["hadoop"]["hdfs"]["balancer"]["max_concurrent_moves_multiplier"] = 10

default[:bcpc][:hadoop][:hdfs][:dfs].tap do |dfs|
  dfs[:namenode][:audit][:log][:async] = true
  dfs[:webhdfs][:enabled] = true
  dfs[:client][:read][:shortcircuit] = true
  dfs[:domain][:socket][:path] = "/var/run/hadoop-hdfs/dn._PORT"
  dfs[:client]['file-block-storage-locations'][:timeout] = 3000
  dfs[:datanode]['hdfs-blocks-metadata'][:enabled] = true
  dfs[:namenode][:datanode][:registration]['ip-hostname-check'] = false
  dfs[:namenode][:avoid][:read][:stale][:datanode] = true
  dfs[:namenode][:avoid][:write][:stale][:datanode] = true
  dfs[:hosts][:exclude] = "/etc/hadoop/conf/dfs.exclude"
  dfs[:datanode][:du][:reserved] = 209715200 # 200 MB
  dfs[:permissions][:superusergroup] = "hdfs"
  dfs[:cluster][:administrators] = "hdfs"
  dfs[:dfs][:ha]['automatic-failover'][:enabled] = true
end

default[:bcpc][:hadoop][:hdfs][:ldap].tap do |ldap|
  ldap[:integration] = false
  ldap[:user] = "" #must be LDAP DN
  ldap[:domain] = "BCPC.EXAMPLE.COM"
  ldap[:port] = 389
  ldap[:password] =  nil
  ldap[:search][:depth] = 0
  ldap[:search][:filter][:user]="(&(objectclass=user)(sAMAccountName={0}))"
  ldap[:search][:filter][:group]="(objectClass=group)"
end

default[:bcpc][:hadoop][:hdfs][:site_xml].tap do |site_xml|
  dfs = node[:bcpc][:hadoop][:hdfs][:dfs]
  
  site_xml['dfs.replication'] =
    node[:bcpc][:hadoop][:hdfs][:dfs_replication_factor]
  
  site_xml['dfs.namenode.audit.log.async'] =
    dfs[:namenode][:audit][:log][:async]


  site_xml['dfs.nameservices'] = node.chef_environment

  site_xml['dfs.datanode.failed.volumes.tolerated'] =
    node[:bcpc][:hadoop][:hdfs][:failed_volumes_tolerated]

  site_xml["dfs.client.failover.proxy.provider.#{node.chef_environment}"] =
    'org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider'

  if node[:bcpc][:hadoop][:hdfs][:HA]
    site_xml['dfs.ha.automatic-failover.enabled'] =
      dfs[:dfs][:ha]['automatic-failover'][:enabled]

    site_xml['dfs.ha.fencing.methods'] =
      'shell(/bin/true)'
  end

  site_xml['dfs.webhdfs.enabled'] =
    dfs[:webhdfs][:enabled]

  site_xml['dfs.client.read.shortcircuit'] =
    dfs[:client][:read][:shortcircuit]
  
  site_xml['dfs.domain.socket.path'] =
    dfs[:domain][:socket][:path]

  site_xml['dfs.client.file-block-storage-locations.timeout'] =
    dfs[:client]['file-block-storage-locations'][:timeout]

  site_xml['dfs.datanode.hdfs-blocks-metadata.enabled'] =
    dfs[:datanode]['hdfs-blocks-metadata'][:enabled]

  site_xml['dfs.namenode.datanode.registration.ip-hostname-check'] =
    dfs[:namenode][:datanode][:registration]['ip-hostname-check']

  site_xml['dfs.namenode.avoid.read.stale.datanode'] =
    dfs[:namenode][:avoid][:read][:stale][:datanode]

  site_xml['dfs.namenode.avoid.write.stale.datanode'] =
    dfs[:namenode][:avoid][:write][:stale][:datanode]

  site_xml['dfs.hosts.exclude'] =
    dfs[:hosts][:exclude]

  site_xml['dfs.datanode.du.reserved'] =
    dfs[:datanode][:du][:reserved]

  site_xml['dfs.blocksize'] =
    node[:bcpc][:hadoop][:hdfs][:dfs_blocksize]

  site_xml['dfs.datanode.max.transfer.threads'] =
    node[:bcpc][:hadoop][:datanode][:max][:xferthreads]
  
  site_xml['dfs.namenode.handler.count'] =
    node[:bcpc][:hadoop][:namenode][:handler][:count]
end
