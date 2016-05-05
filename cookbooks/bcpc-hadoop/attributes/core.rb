# As far as I know, none of these are used outside core-site.xml
default[:bcpc][:hadoop][:core].tap do |core|
  core["yarn"]["nodemanager"]["linux-container-executor"]["group"] = "yarn"
  core["mapreduce"]["framework"]["name"] = "yarn"
  core["net"]["topology"]["script"]["file"]["name"] = "/etc/hadoop/conf/topology"
  core["hadoop"]["user"]["group"]["static"]["mapping"]["overrides"] = "hdfs=hadoop,hdfs;yarn=mapred,hadoop;mapred=mapred;"
  core["hadoop"]["security"]["group"]["mapping"]["ldap"]["bind"]["password"]["file"] = "/etc/hadoop/conf/ldap-conn-pass.txt"
  core["hadoop"]["security"]["group"]["mapping"]["ldap"]["search"]["attr"]["member"] = "member"
  core["hadoop"]["security"]["group"]["mapping"]["ldap"]["search"]["attr"]["group"]["name"] = "cn"
end

default[:bcpc][:hadoop][:core][:site_xml].tap do |site_xml|
  site_xml['fs.defaultFS'] = node[:bcpc][:hadoop][:hdfs_url]
  site_xml['hadoop.proxyuser.hive.hosts'] = '*'
  site_xml['hadoop.proxyuser.hive.groups'] = '*'
  site_xml['hadoop.proxyuser.httpsfs.hosts'] = '*'
  site_xml['hadoop.proxyuser.httpsfs.groups'] = '*'
  site_xml['hadoop.proxyuser.hue.hosts'] = '*'
  site_xml['hadoop.proxyuser.hue.groups'] = '*'
  site_xml['hadoop.proxyuser.oozie.hosts'] = '*'
  site_xml['hadoop.proxyuser.oozie.groups'] = '*'
  
  site_xml['hadoop.user.group.static.mapping.overrides'] =
    'hdfs=hadoop,hdfs;yarn=mapred,hadoop;mapred=mapred;'

  site_xml['io.compression.codecs'] =
    [
     'org.apache.hadoop.io.compress.DefaultCodec',
     'org.apache.hadoop.io.compress.GzipCodec',
     'org.apache.hadoop.io.compress.BZip2Codec',
     'com.hadoop.compression.lzo.LzoCodec',
     'com.hadoop.compression.lzo.LzopCodec',
     'org.apache.hadoop.io.compress.SnappyCodec',
    ].join(',')

  site_xml['io.compression.codec.lzo.class'] =
    'com.hadoop.compression.lzo.LzoCodec'

  site_xml['mapreduce.framework.name'] =
    node[:bcpc][:hadoop][:mapreduce][:framework][:name]

  site_xml['net.topology.script.file.name'] = '/etc/hadoop/conf/topology'
  site_xml['yarn.nodemanager.linux-container-executor.group'] = 'yarn'
end
