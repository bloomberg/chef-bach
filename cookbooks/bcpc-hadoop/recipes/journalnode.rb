
%w{hadoop-hdfs-journalnode}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

directory "/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/jn/bcpc/current" do
  owner "hdfs"
  group "hdfs"
  mode 0755
  action :create
  recursive true
end

file "/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/jn/bcpc/current/VERSION" do
  owner "hdfs"
  group "hdfs"
  mode 0755
  content get_config("journalnode_txn_fmt")
  only_if node[:bcpc][:hadoop][:standby]
end

service "hadoop-hdfs-journalnode" do
  action :enable
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end



