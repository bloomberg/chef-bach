

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


if node[:bcpc][:hadoop][:standby] then
#    bash "bootstrap standby" do
#      code "hdfs namenode -bootstrapStandby"
#      user "hdfs"
#      action :run
#    end

bash "work around retarded -bootstrapStandby bug" do
   creates "/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION"
end

else

  bash "format namenode" do
    code "hdfs namenode -format"
    user "hdfs"
    action :run
    creates "/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION"
  end


end

bash "format-zk-hdfs-ha" do
  code "hdfs zkfc -formatZK"
  action :run
  user "hdfs"
  #TODO need a not_if or creates check in zookeeper
end

service "hadoop-hdfs-zkfc" do
  action :enable
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end

service "hadoop-hdfs-namenode" do
  action :enable
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end




