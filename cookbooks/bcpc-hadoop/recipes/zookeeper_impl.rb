
include_recipe 'dpkg_autostart'
include_recipe 'bcpc-hadoop::zookeeper_config'
dpkg_autostart "zookeeper-server" do
  allow false
end

package  "zookeeper-server" do
  action :upgrade
  notifies :create, "template[/tmp/zkServer.sh]", :immediately
  notifies :create, "ruby_block[Compare_zookeeper_server_start_shell_script]", :immediately
end

template "/tmp/zkServer.sh" do
  source "hdp_zkServer.sh.orig.erb"
  mode 0644
end

ruby_block "Compare_zookeeper_server_start_shell_script" do
  block do
    require "digest"
    orig_checksum=Digest::MD5.hexdigest(File.read("/tmp/zkServer.sh"))
    new_checksum=Digest::MD5.hexdigest(File.read("/usr/hdp/2.2.0.0-2041/zookeeper/bin/zkServer.sh"))
    if orig_checksum != new_checksum
      Chef::Application.fatal!("zookeeper-server:New version of zkServer.sh need to be created and used")
    end
  end
  action :nothing
end

template "/etc/init.d/zookeeper-server" do
  source "hdp_zookeeper-server-initd.erb"
  mode 0655
end

directory "/var/run/zookeeper" do 
  owner "zookeeper"
  group "zookeeper"
  mode "0755"
  action :create
end

link "/usr/bin/zookeeper-server-initialize" do
  to "/usr/hdp/current/zookeeper-client/bin/zookeeper-server-initialize"
end

template "/etc/init.d/zookeeper-server" do
  source "hdp_zookeeper-server-initd.erb"
  mode 0655
end

template "/etc/zookeeper/conf/zookeeper-env.sh" do
  source "hdp_zookeeper-env.sh.erb"
  mode 0644
  variables(:zk_jmx_port => node[:bcpc][:hadoop][:zookeeper][:jmx][:port])
end

directory node[:bcpc][:hadoop][:zookeeper][:data_dir] do
  recursive true
  owner node[:bcpc][:hadoop][:zookeeper][:owner]
  group node[:bcpc][:hadoop][:zookeeper][:group]
  mode 0755
end

#template "/etc/default/zookeeper-server" do
#  source "hdp_zookeeper-server.default.erb"
#  mode 0644
#  variables(:zk_jmx_port => node[:bcpc][:hadoop][:zookeeper][:jmx][:port])
#end

template "/usr/hdp/2.2.0.0-2041/zookeeper/bin/zkServer.sh" do
  source "hdp_zkServer.sh.erb"
end

bash "init-zookeeper" do
  code "service zookeeper-server init --myid=#{node[:bcpc][:node_number]}"
  not_if { ::File.exists?("#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid") }
end

file "#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid" do
  content node[:bcpc][:node_number]
  owner node[:bcpc][:hadoop][:zookeeper][:owner]
  group node[:bcpc][:hadoop][:zookeeper][:group]
  mode 0644
end

service "zookeeper-server" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zoo.cfg]", :delayed
  subscribes :restart, "template[#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zookeeper-env.sh]", :delayed
  subscribes :restart, "template[/usr/lib/zookeeper/bin/zkServer.sh]", :delayed
  subscribes :restart, "template[/etc/default/zookeeper-server]", :delayed
  subscribes :restart, "file[#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid]", :delayed
end
