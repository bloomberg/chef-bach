# Kerberos settings 
default[:bcpc][:hadoop][:kerberos][:enable] = false
default[:bcpc][:hadoop][:kerberos][:realm] = "BCPC.EXAMPLE.COM"
default[:bcpc][:hadoop][:kerberos][:data] = {
        :namenode => {"principal" => "nn", "keytab" => "nn.service.keytab", "owner" => "hdfs", "princhost" => "_HOST", "perms"=> "0600", "spnego_keytab" => "nn.service.keytab"},
        :datanode => {"principal" => "dn", "keytab" => "dn.service.keytab", "owner" => "hdfs", "princhost" => "_HOST", "perms"=> "0600", "spnego_keytab" => "dn.service.keytab"},
        :journalnode => {"principal" => "jn", "keytab" => "jn.service.keytab", "owner" => "hdfs", "princhost" => "_HOST", "perms"=> "0600", "spnego_keytab" => "jn.service.keytab"},
        :resourcemanager => {"principal" => "rm", "keytab" => "rm.service.keytab", "owner" => "yarn", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "rm.service.keytab"},
        :nodemanager => {"principal" => "nm", "keytab" => "nm.service.keytab", "owner" => "yarn", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "nm.service.keytab"},
        :historyserver => {"principal" => "jhs", "keytab" => "jhs.service.keytab", "owner" => "mapred", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "jhs.service.keytab"},
        :spnego => {"principal" => "HTTP", "keytab" => "spnego.service.keytab", "owner" => "hdfs", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "spnego.service.keytab"},
        :zookeeper => {"principal" => "zookeeper", "keytab" => "zookeeper.service.keytab", "owner" => "zookeeper", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "zookeeper.service.keytab"},
        :hbase => {"principal" => "hbase", "keytab" => "hbase.service.keytab", "owner" => "hbase", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" =>  "hbase.service.keytab"},
        :httpfs => {"principal" => "httpfs", "keytab" => "httpfs.service.keytab", "owner" => "httpfs", "princhost"  => "_HOST", "perms" => "0600", "spnego_keytab" => "httpfs.service.keytab"},
        :hive => {"principal" => "hive", "keytab" => "hive.service.keytab", "owner" => "hive", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "hive.service.keytab"},
        :oozie => {"principal" => "oozie", "keytab" => "oozie.service.keytab", "owner" => "oozie", "princhost" => "_HOST", "perms" => "0600", "spnego_keytab" => "oozie.service.keytab"}}
default[:bcpc][:hadoop][:kerberos][:keytab][:dir] = "/etc/security/keytabs"
default[:bcpc][:hadoop][:kerberos][:keytab][:recreate] = false
