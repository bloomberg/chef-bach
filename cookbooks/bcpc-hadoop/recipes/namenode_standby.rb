include_recipe 'dpkg_autostart'
require "base64"

template "/etc/hadoop/conf/hdfs-site.xml" do
  source "hdp_hdfs-site.xml.erb"
  mode 0644
  variables(:nn_hosts => get_nodes_for("namenode*") ,
       :zk_hosts => get_nodes_for("zookeeper_server"),
       :jn_hosts => get_nodes_for("journalnode"),
       :rm_host  => get_nodes_for("resource_manager"),
       :dn_hosts => get_nodes_for("datanode"),
       :mounts => node[:bcpc][:hadoop][:mounts])
end

%w{hadoop-hdfs-namenode hadoop-hdfs-zkfc}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
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

if get_config("namenode_txn_fmt") then
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
  end

  bash "unpack nn fmt image" do
    user "hdfs"
    get_config("namenode_txn_fmt")
    code ["pushd /disk/#{d}/dfs/",
          "tar xzvf /tmp/nn_fmt.tgz",
          "popd"].join("\n")
    only_if { not get_config("namenode_txn_fmt").nil? }
  end
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

