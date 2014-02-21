%w{
hbase
hbase-master
hbase-thrift
}.each do |p|
  package p do
    action :install
  end
end

bash "create-hbase-dir" do
  code "hadoop fs -mkdir -p /hbase; hadoop fs -chown hbase:hadoop /hbase"
  user "hdfs"
  not_if "sudo -u hdfs hadoop fs -test -d /hbase"
end

service "hbase-master" do
  action [:enable, :start]
end
