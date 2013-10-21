

%w{hadoop-hdfs-namenode hadoop-hdfs-zkfc}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

node[:bcpc][:hadoop][:mounts].each do |i|

  directory "/disk/#{i}/dfs/nn" do
    owner "hdfs"
    group "hdfs"
    mode 0700
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

if not File.exists?("/disk/#{node[:bcpc][:hadoop][:mount][0]}/dfs/nn/current/VERSION") then 
  if get_hadoop_heads.length > 1 and not node[:bcpc][:hadoop][:override_standby] then
    bash "bootstrap standby" do
      code "hdfs namenode -bootstrapStandby"
      user "hdfs"
      action :run
    end

  else

    bash "format namenode" do
      code "hadoop namenode -format"
      user "hdfs"
      action :run
    end

    bash "format-zk-hdfs-ha" do
      code "hdfs zkfc -formatZK"
      action :run
      user "hdfs"
    end

  end 
end 

service "hadoop-hdfs-zkfc" do
  action [:enable, :restart]
end

service "hadoop-hdfs-namenode" do
  action [:enable, :restart]
end




