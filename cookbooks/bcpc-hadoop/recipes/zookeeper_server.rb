
include_recipe 'dpkg_autostart'

%w{zookeeper-server}.each do |pkg|
  dpkg_autostart pkg do
    allow false
  end
  package  pkg do
    action :upgrade
    notifies :create, "template[/tmp/zkServer.sh]", :immediately
    notifies :create, "ruby_block[Compare_zookeeper_server_start_shell_script]", :immediately
  end
end

template "/tmp/zkServer.sh" do
  source "hdp_zkServer.sh.orig.erb"
  mode 0644
end

ruby_block "Compare_zookeeper_server_start_shell_script" do
  block do
    require "digest"
    orig_checksum=Digest::MD5.hexdigest(File.read("/tmp/zkServer.sh"))
    new_checksum=Digest::MD5.hexdigest(File.read("/usr/lib/zookeeper/bin/zkServer.sh"))
    if orig_checksum != new_checksum
      Chef::Application.fatal!("zookeeper-server:New version of zkServer.sh need to be created and used")
    end
  end
  action :nothing
end

template "/etc/init.d/zookeeper-server" do
  source "hdp_zookeeper-server.start.erb"
  mode 0655
end

directory "/var/lib/zookeeper" do
  recursive true
  owner "zookeeper"
  group "zookeeper"
  mode 0755
end

template "/etc/default/zookeeper-server" do
  source "hdp_zookeeper-server.default.erb"
  mode 0644
  variables(:zk_jmx_port => node[:bcpc][:hadoop][:zookeeper][:jmx][:port])
end

template "/usr/lib/zookeeper/bin/zkServer.sh" do
  source "hdp_zkServer.sh.erb"
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

