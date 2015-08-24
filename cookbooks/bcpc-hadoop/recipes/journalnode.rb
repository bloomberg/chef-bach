require 'base64'
include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::hadoop_config'

%w{hadoop-hdfs-namenode }.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

if get_config("namenode_txn_fmt") then
  file "#{Chef::Config[:file_cache_path]}/nn_fmt.tgz" do
    user "hdfs"
    group "hdfs"
    user 0644
    content Base64.decode64(get_config("namenode_txn_fmt"))
    not_if { node[:bcpc][:hadoop][:mounts].all? { |d| File.exists?("/disk/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") } }
  end
end

node[:bcpc][:hadoop][:mounts].each do |d|

  # Per chef-documentation for directory resource's recursive attribute:
  # For the owner, group, and mode attributes, the value of this attribute applies only to the leaf directory
  # Hence, we create "/disk/#{d}/dfs/jn/" to have "jn" dir owned by hdfs and then
  # create "/disk/#{d}/dfs/jn/#{node.chef_environment}" owned by hdfs. 
  # This way the jn/{environment} dir tree is owned by hdfs
  
  directory "/disk/#{d}/dfs/jn" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

  directory "/disk/#{d}/dfs/jn/#{node.chef_environment}" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

  bash "unpack-nn-fmt-image-to-disk-#{d}" do
    user "root"
    cwd "/disk/#{d}/dfs/"
    code "tar xpzvf #{Chef::Config[:file_cache_path]}/nn_fmt.tgz"
    notifies :restart, "service[hadoop-hdfs-journalnode]"
    only_if { not get_config("namenode_txn_fmt").nil? and not File.exists?("/disk/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") }
  end
end

template "hadoop-hdfs-journalnode" do
  path "/etc/init.d/hadoop-hdfs-journalnode"
  source "hdp_hadoop-hdfs-journalnode-initd.erb"
  owner "root"
  group "root"
  mode "0755"
  notifies :restart, "service[hadoop-hdfs-journalnode]"
end

service "hadoop-hdfs-journalnode" do
  action [:start, :enable]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site_HA.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
end
