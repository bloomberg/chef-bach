
%w{hadoop-hdfs-journalnode}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

directory "/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/jn" do
  owner "hdfs"
  group "hdfs"
  mode 0755
  action :create
  recursive true
end

service "hadoop-hdfs-journalnode" do
  action :enable
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end



