

%w{hadoop-hdfs-namenode hadoop-hdfs-zkfc}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

node[:bcpc][:hadoop][:mounts].each do |i|

  directory "/disk/#{i}/dfs/nn" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

  directory "/disk/#{i}/dfs/namedir" do
    owner "hdfs"
    group "hdfs"
    mode 0700
    action :create
    recursive true
  end

end



node[:bcpc][:hadoop][:mounts].each do |d|

  directory "/disk/#{d}/dfs/nn/current" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
    only_if node[:bcpc][:hadoop][:standby]
  end

  file "/disk/#{d}/dfs/nn/current/VERSION" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    content get_config("namenode_txn_fmt")
    only_if node[:bcpc][:hadoop][:standby]
  end
end


bash "format namenode" do
  code "hdfs namenode -format"
  user "hdfs"
  action :run
  creates "/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION"
  not_if node[:bcpc][:hadoop][:standby]
end


bash "format-zk-hdfs-ha" do
  code "hdfs zkfc -formatZK"
  action :run
  user "hdfs"
  #TODO need a not_if or creates check in zookeeper
  not_if node[:bcpc][:hadoop][:standby]
end

service "hadoop-hdfs-zkfc" do
  action :enable
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
end

service "hadoop-hdfs-namenode" do
  action :enable
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
end


## We need to bootstrap the standby and journal node transaction logs
# The -bootstrapStandby and -initializeSharedEdits don't actually work
# when the namenode starts up, because it is in safemode and won't commit
# a txn.
# So we fake the formatting of the txn directories by copying over current/VERSION
# this tricks the journalnodes and namenodes into thinking they've been formatted.
ruby_block "grab the format UUID File" do
  block do
    make_config("namenode_txn_fmt", IO.read("/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION"));
    make_config("journalnode_txn_fmt", IO.read("/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/jn/bcpc/current/VERSION"));
  end
  action :nothing
  subscribes :create, "service[hadoop-hdfs-namenode]", :immediate
end
