# Kerberos settings
default[:bcpc][:hadoop][:kerberos][:enable] = true
default[:bcpc][:hadoop][:kerberos][:realm] = "BCPC.EXAMPLE.COM"
default['bcpc']['hadoop']['kerberos']['data'] = {
  namenode: {
    principal: 'hdfs',
    keytab: 'hdfs.service.keytab',
    owner: 'hdfs',
    group: 'hadoop',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  datanode: {
    principal: 'hdfs',
    keytab: 'hdfs.service.keytab',
    owner: 'hdfs',
    group: 'hadoop',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  journalnode: {
    principal: 'hdfs',
    keytab: 'hdfs.service.keytab',
    owner: 'hdfs',
    group: 'hadoop',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  resourcemanager: {
    principal: 'yarn',
    keytab: 'yarn.service.keytab',
    owner: 'yarn',
    group: 'yarn',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  nodemanager: {
    principal: 'yarn',
    keytab: 'yarn.service.keytab',
    owner: 'yarn',
    group: 'yarn',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  historyserver: {
    principal: 'mapred',
    keytab: 'mapred.service.keytab',
    owner: 'mapred',
    group: 'hadoop',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  spnego: {
    principal: 'HTTP',
    keytab: 'spnego.service.keytab',
    owner: 'hdfs',
    group: 'hadoop',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  zookeeper: {
    principal: 'zookeeper',
    keytab: 'zookeeper.service.keytab',
    owner: 'zookeeper',
    group: 'zookeeper',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  hbase: {
    principal: 'hbase',
    keytab: 'hbase.service.keytab',
    owner: 'hbase',
    group: 'hbase',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  httpfs: {
    principal: 'httpfs',
    keytab: 'httpfs.service.keytab',
    owner: 'httpfs',
    group: 'hadoop',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  hive: {
    principal: 'hive',
    keytab: 'hive.service.keytab',
    owner: 'hive',
    group: 'hive',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  oozie: {
    principal: 'oozie',
    keytab: 'oozie.service.keytab',
    owner: 'oozie',
    group: 'oozie',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  hannibal: {
    principal: 'hannibal',
    keytab: 'hannibal.service.keytab',
    owner: 'hbase',
    group: 'hbase',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  backup: {
    principal: node[:bcpc][:hadoop][:backup][:user],
    keytab: 'backup.service.keytab',
    owner: node[:bcpc][:hadoop][:backup][:user],
    group: node[:bcpc][:hadoop][:backup][:user],
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  },
  ambari: {
      principal: "#{node['bcpc']['hadoop']['proxyuser']['ambari']}",
      keytab: 'ambari.service.keytab',
      owner: "#{node['bcpc']['hadoop']['proxyuser']['ambari']}",
      group: 'root',
      princhost: '_HOST',
      perms: '0440',
      spnego_keytab: 'spnego.service.keytab'
          },
  kafka: {
    principal: 'kafka',
    keytab: 'kafka.service.keytab',
    owner: 'kafka',
    group: 'kafka',
    princhost: '_HOST',
    perms: '0440',
    spnego_keytab: 'spnego.service.keytab'
  }
}
default[:bcpc][:hadoop][:kerberos][:keytab][:dir] = "/etc/security/keytabs"
default[:bcpc][:hadoop][:kerberos][:keytab][:recreate] = false
