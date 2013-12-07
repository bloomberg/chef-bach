include_recipe 'dpkg_autostart'

%w{hadoop-hdfs-journalnode}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package pkg do
    action :upgrade
  end
end

node[:bcpc][:hadoop][:mounts].each do |i|
  directory "/disk/#{i}/dfs/jn" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end
end

service "hadoop-hdfs-journalnode" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
end



