

%w{hadoop-hdfs-namenode hadoop-hdfs-zkfc}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

mgmt_hostaddr = IPAddr.new(node['bcpc']['management']['ip'])<<24>>24
node[:bcpc][:namenode][:id] = mgmt_hostaddr

(1..4).each do |i|

  directory "/disk#{i}/dfs/nn" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
    recursive true
  end

  directory "/disk#{i}/dfs/namedir" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
    recursive true
  end

end


bash "format namenode" do
  code "hadoop namenode -format"
  user "hdfs"
  action :run
  not_if { File.exists?("/disk1/dfs/namedir/VERSION") or File.exists?("/disk1/dfs/nn/current/VERSION") }
end


bash "bootstrap standby" do
  code "hdfs namenode -bootstrapStandby"
  user "hdfs"
  action :run
end


service "hadoop-hdfs-namenode" do
  action [:enable, :restart]
end

service "hadoop-hdfs-zkfc" do
  action [:enable, :restart]
end

bash "format-zk-hdfs-ha" do
  code "hdfs zkfc -formatZK"
  action :run
  user "hdfs"
end


