require 'base64'
include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::hadoop_config'

mount_root = node["bcpc"]["storage"]["disks"]["mount_root"]

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
    not_if { lazy { node[:bcpc][:storage][:mounts].all? { |d| File.exists?("#{mount_root}/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") } } }
  end
end

ruby_block "create journalnode directories" do
  block do
    node[:bcpc][:storage][:mounts].each do |d|
      dir = Chef::Resource::Directory.new("#{mount_root}/#{d}/dfs/jn/", run_context)
      dir.owner "hdfs"
      dir.group "hdfs"
      dir.mode 0755
      dir.recursive true
      dir.run_action :create

      dir = Chef::Resource::Directory.new("#{mount_root}/#{d}/dfs/jn/#{node.chef_environment}", run_context)
      dir.owner "hdfs"
      dir.group "hdfs"
      dir.mode 0755
      dir.recursive true
      dir.run_action :create

      bash = Chef::Resource::Bash.new("unpack nn fmt image", run_context)
      bash.user "hdfs"
      bash.code ["pushd #{mount_root}/#{d}/dfs/",
                 "tar xzvf #{Chef::Config[:file_cache_path]}/nn_fmt.tgz",
                 "popd"].join("\n")
      bash.notifies :restart, "service[hadoop-hdfs-journalnode]", :delayed
      bash.only_if { not get_config("namenode_txn_fmt").nil? and not File.exists?("#{mount_root}/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") }
    end
  end
end

link "/usr/lib/hadoop-hdfs/libexec" do
  to "/usr/lib/hadoop/libexec"
end

template "hadoop-hdfs-journalnode" do
  path "/etc/init.d/hadoop-hdfs-journalnode"
  source "hdp_hadoop-hdfs-journalnode.erb"
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
end
