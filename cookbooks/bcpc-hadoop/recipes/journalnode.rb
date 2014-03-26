include_recipe 'dpkg_autostart'

%w{hadoop-hdfs-namenode }.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/dfs/jn/" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end
  directory "/disk/#{i}/dfs/jn/#{node.chef_environment}" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
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
  notifies :enable, "service[hadoop-hdfs-journalnode]"
  notifies :start, "service[hadoop-hdfs-journalnode]"
end


service "hadoop-hdfs-journalnode" do
  action :nothing
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "bash[initialize-shared-edits]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site_HA.xml]", :delayed
  subscribes :restart, "template[hadoop-hdfs-journalnode]", :immediately
end

