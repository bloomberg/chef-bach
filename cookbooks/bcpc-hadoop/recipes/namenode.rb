require "base64"

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
  
  execute "fixup nn owner" do
    command "chown -Rf hdfs:hdfs /disk/#{i}/dfs/"
    only_if { Etc.getpwuid(File.stat("/disk/#{i}/dfs/").uid).name != "hdfs" }
  end
end

if node[:bcpc][:hadoop][:standby] and get_config("namenode_txn_fmt") then
  file "/tmp/nn_fmt.tgz" do
    user "hdfs"
    group "hdfs"
    user 0644
    content Base64.decode64(get_config("namenode_txn_fmt"))
  end
end 

node[:bcpc][:hadoop][:mounts].each do |d|

  directory "/disk/#{d}/dfs/" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
    only_if { node[:bcpc][:hadoop][:standby] }
  end
  
  bash "unpack nn fmt image" do 
    user "hdfs"
    get_config("namenode_txn_fmt")
    code ["pushd /disk/#{d}/dfs/",
          "tar xzvf /tmp/nn_fmt.tgz",
          "popd"].join("\n")
    only_if { node[:bcpc][:hadoop][:standby] and (not get_config("namenode_txn_fmt").empty?) }
  end
end


bash "format namenode" do
  code "hdfs namenode -format"
  user "hdfs"
  action :run
  creates "/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION"
  not_if { node[:bcpc][:hadoop][:standby] }
end

bash "format-zk-hdfs-ha" do
  code "hdfs zkfc -formatZK"
  action :run
  user "hdfs"
  not_if { zk_formatted? }
end

service "hadoop-hdfs-zkfc" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
end

service "hadoop-hdfs-namenode" do
  action [:enable, :start]
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
    Dir.chdir("/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/") do
      system("tar czvf /tmp/nn_fmt.tgz nn/")
    end
    make_config("namenode_txn_fmt", Base64.encode64(IO.read("/tmp/nn_fmt.tgz")));
    make_config("journalnode_txn_fmt", IO.read("/disk/#{node[:bcpc][:hadoop][:mounts][1]}/dfs/jn/bcpc/current/VERSION"));
  end
  action :nothing
  subscribes :create, "service[hadoop-hdfs-namenode]", :immediate
  only_if { File.exists?("/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION") }
end
