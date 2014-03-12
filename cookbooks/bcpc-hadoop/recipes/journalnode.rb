include_recipe 'dpkg_autostart'

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

bash "start-journalnode" do
  code "/usr/lib/hadoop/sbin/hadoop-daemon.sh start journalnode"
  action :run
  not_if "ps -ef | grep -v grep | grep journalnode"
end




