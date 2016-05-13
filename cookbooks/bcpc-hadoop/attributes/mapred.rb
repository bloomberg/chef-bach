require 'shellwords'

# These should probably be deleted when the old templates are removed.
# They are only used here.
default["bcpc"]["hadoop"]["mapreduce"]["map"]["output"]["compress"] = true
default["bcpc"]["hadoop"]["mapred"]["map"]["output"]["compress"]["codec"] = "org.apache.hadoop.io.compress.SnappyCodec"
default["bcpc"]["hadoop"]["yarn"]["app"]["mapreduce"]["am"]["log"]["level"] = "DEBUG"
default["bcpc"]["hadoop"]["yarn"]["app"]["mapreduce"]["am"]["staging-dir"] = "/user"

default[:bcpc][:hadoop][:mapreduce][:site_xml].tap do |site_xml|
  site_xml['mapreduce.admin.map.child.java.opts'] =
    '-server -Djava.net.preferIPv4Stack=true -Dhdp.version=' +
    node[:bcpc][:hadoop][:distribution][:release].to_s

  hdp_path =
    File.join('/usr/hdp',
              node[:bcpc][:hadoop][:distribution][:active_release])
  
  site_xml['mapreduce.admin.user.env'] =
    'LD_LIBRARY_PATH=' +
    [
     File.join(hdp_path, 'hadoop', 'lib', 'native'),
     File.join(hdp_path, 'hadoop', 'lib', 'native', 'Linux-amd64-64'),
    ].map{ |s| s.shellescape }.join(':')

  site_xml['mapreduce.framework.name'] =
    node["bcpc"]["hadoop"]["mapreduce"]["framework"]["name"]

  site_xml['mapreduce.application.classpath'] =
    [
     '$PWD/mr-framework/hadoop/share/hadoop/mapreduce/*',
     '$PWD/mr-framework/hadoop/share/hadoop/mapreduce/lib/*',
     '$PWD/mr-framework/hadoop/share/hadoop/common/*',
     '$PWD/mr-framework/hadoop/share/hadoop/common/lib/*',
     '$PWD/mr-framework/hadoop/share/hadoop/yarn/*',
     '$PWD/mr-framework/hadoop/share/hadoop/yarn/lib/*',
     '$PWD/mr-framework/hadoop/share/hadoop/hdfs/*',
     '$PWD/mr-framework/hadoop/share/hadoop/hdfs/lib/*',
     "#{hdp_path}/hadoop/lib/hadoop-lzo-0.6.0." +
       "#{node[:bcpc][:hadoop][:distribution][:active_release]}.jar",
     "#{hdp_path}/phoenix/phoenix-server.jar",
     '$HADOOP_CONF_DIR',
    ].join(',')

  site_xml['mapreduce.application.framework.path'] =
    File.join(hdp_path, 'mapreduce', 'mapreduce.tar.gz#mr-framework')

  site_xml['mapreduce.map.output.compress'] = true

  site_xml['mapred.map.output.compress.codec'] =
    "org.apache.hadoop.io.compress.SnappyCodec"

  site_xml['yarn.app.mapreduce.am.log.level'] =
    node["bcpc"]["hadoop"]["yarn"]["app"]["mapreduce"]["am"]["log"]["level"]

  site_xml['yarn.app.mapreduce.am.staging-dir'] =
    node["bcpc"]["hadoop"]["yarn"]["app"]["mapreduce"]["am"]["staging-dir"]

  min_allocation =
    node['bcpc']['hadoop']['yarn']['scheduler']['minimum-allocation-mb']

  site_xml['mapreduce.map.memory.mb'] =
    min_allocation.round
 
  site_xml['mapreduce.map.java.opts'] =
    "-Xmx" + (0.8 * min_allocation).round.to_s + "m"

  site_xml['mapreduce.reduce.memory.mb'] =
    2 * min_allocation.round
  
  site_xml['mapreduce.reduce.java.opts'] =
    "-Xmx" + (0.8 * 2 * min_allocation).round.to_s + "m"

  site_xml['yarn.app.mapreduce.am.resource.mb'] =
    2 * min_allocation.round
  
  site_xml['yarn.app.mapreduce.am.command-opts'] =
    "-Xmx" + (0.8 * 2 * min_allocation).round.to_s + "m"
end
