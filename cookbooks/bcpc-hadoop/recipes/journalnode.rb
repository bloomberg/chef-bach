
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

execute "fixup journal dir owner" do
  command "chown -Rf hdfs:hdfs /disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/"
  only_if { Etc.getpwuid(File.stat("/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/").uid).name != "hdfs" }
end

file "/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/jn/bcpc/current/VERSION" do
  owner "hdfs"
  group "hdfs"
  mode 0755
  content get_config("journalnode_txn_fmt")
  only_if { node[:bcpc][:hadoop][:standby] and not get_config("journalnode_txn_fmt").empty? }
end

service "hadoop-hdfs-journalnode" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end



