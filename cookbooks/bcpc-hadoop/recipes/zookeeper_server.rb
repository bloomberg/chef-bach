
include_recipe 'dpkg_autostart'

%w{zookeeper-server}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package  pkg do
    action :upgrade
  end
end

directory "/var/lib/zookeeper" do
  recursive true
  owner "zookeeper"
  group "zookeeper"
  mode 0755
end

bash "init-zookeeper" do
  code "service zookeeper-server init --myid=#{node[:bcpc][:node_number]}"
  creates "/var/lib/zookeeper/myid"
end

file "/var/lib/zookeeper/myid" do
  content node[:bcpc][:node_number]
  owner "zookeeper"
  group "zookeeper"
  mode 0644
end

service "zookeeper-server" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/zookeeper/conf/zoo.cfg]", :delayed
end

