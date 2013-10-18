


package "zookeeper-server" do
  action :upgrade
end


mgmt_hostaddr = IPAddr.new(node['bcpc']['management']['ip'])<<24>>24
node[:bcpc][:zookeeper][:id] = mgmt_hostaddr.to_i.to_s

directory "/var/lib/zookeeper" do
  recursive true
  owner "zookeeper"
  group "zookeeper"
  mode 0755
end

file "/var/lib/zookeeper/myid" do
  content "#{node[:bcpc][:zookeeper][:id]}"
  owner "zookeeper"
  group "zookeeper"
  mode 0644
end

bash "init-zookeeper" do
  code "service zookeeper-server init && touch /var/lib/zookeeper/done"
  creates "/var/lib/zookeeper/done"
end

service "zookeeper-server" do
  action [:enable, :start]
end

