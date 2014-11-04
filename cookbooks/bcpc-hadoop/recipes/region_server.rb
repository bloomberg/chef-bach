include_recipe 'bcpc-hadoop::hbase_config'

%w{hbase-regionserver libsnappy1}.each do |pkg|
  package pkg do
    action :install
  end
end

directory "/usr/lib/hbase/lib/native/Linux-amd64-64/" do
  recursive true
  action :create
end

link "/usr/lib/hbase/lib/native/Linux-amd64-64/libsnappy.so.1" do
  to "/usr/lib/libsnappy.so.1"
end

rs_service_dep = ["template[/etc/hbase/conf/hbase-site.xml]",
                  "template[/etc/hbase/conf/hbase-env.sh]",
                  "template[/etc/hbase/conf/hbase-policy.xml]"] 

hadoop_service "hbase-regionserver" do
  dependencies rs_service_dep
  process_identifier "org.apache.hadoop.hbase.regionserver.HRegionServer"
end
