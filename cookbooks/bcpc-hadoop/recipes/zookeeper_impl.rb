::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

package  hwx_pkg_str('zookeeper-server', node[:bcpc][:hadoop][:distribution][:release]) do
  action :install
end

include_recipe 'bcpc-hadoop::zookeeper_config'

hdp_select('zookeeper-server', node[:bcpc][:hadoop][:distribution][:active_release])

user_ulimit "zookeeper" do
  filehandle_limit 65536
end

configure_kerberos 'zookeeper_kerb' do
  service_name 'zookeeper'
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

template "#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zookeeper-env.sh" do
  source "zk_zookeeper-env.sh.erb"
  mode 0644
  variables(:zk_jmx_port => node[:bcpc][:hadoop][:zookeeper][:jmx][:port])
end

directory node[:bcpc][:hadoop][:zookeeper][:data_dir] do
  recursive true
  owner node[:bcpc][:hadoop][:zookeeper][:owner]
  group node[:bcpc][:hadoop][:zookeeper][:group]
  mode 0755
end

template "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/zookeeper/bin/zkServer.sh" do
  source "zk_zkServer.sh.erb"
end

link '/etc/init.d/zookeeper-server' do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/zookeeper/etc/init.d/zookeeper-server"
  notifies :run, 'bash[kill zookeeper-org-apache-zookeeper-server-quorum-QuorumPeerMain]', :immediate
end

bash "kill zookeeper-org-apache-zookeeper-server-quorum-QuorumPeerMain" do
  code "pkill -u zookeeper -f org.apache.zookeeper.server.quorum.QuorumPeerMain"
  action :nothing
  returns [0, 1]
end

bash 'init-zookeeper' do
  code "service zookeeper-server init " +
    "--myid=#{bcpc_8bit_node_number}"
  
  not_if do
    ::File.exists?("#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid")
  end
  
  # race immediate run of restarting ZK on initial stand-up
  subscribes :run, "link[/etc/init.d/zookeeper-server]", :immediate
end

file "#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid" do
  content bcpc_8bit_node_number.to_s
  owner node[:bcpc][:hadoop][:zookeeper][:owner]
  group node[:bcpc][:hadoop][:zookeeper][:group]
  mode 0644
  # race immediate run of restarting ZK on initial stand-up
  subscribes :create, "bash[init-zookeeper]", :immediate
end

service "zookeeper-server" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "link[/etc/init.d/zookeeper-server]", :immediate
  subscribes :restart, "template[#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zoo.cfg]", :delayed
  subscribes :restart, "template[#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/zookeeper-env.sh]", :delayed
  subscribes :restart, "link[/usr/lib/zookeeper/bin/zkServer.sh]", :delayed
  subscribes :restart, "file[#{node[:bcpc][:hadoop][:zookeeper][:data_dir]}/myid]", :delayed
  subscribes :restart, "user_ulimit[zookeeper]", :delayed
  subscribes :restart, "bash[hdp-select zookeeper-server]", :delayed
  subscribes :restart, "log[jdk-version-changed]", :delayed
end
