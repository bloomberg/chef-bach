::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, BCPC::Utils)
::Chef::Resource::File.send(:include, BCPC::Utils)

include_recipe 'bcpc-hadoop::zookeeper_packages'

user_ulimit 'zookeeper' do
  filehandle_limit 65_536
end

configure_kerberos 'zookeeper_kerb' do
  service_name 'zookeeper'
end

directory '/var/run/zookeeper' do
  owner 'zookeeper'
  group 'zookeeper'
  mode 0755
  action :create
end

link '/usr/bin/zookeeper-server-initialize' do
  to "/usr/hdp/#{node['bcpc']['hadoop']['distribution']['active_release']}/zookeeper-client/bin/zookeeper-server-initialize"
end

# Install jolokia's jvm agent to node['bcpc']['jolokia']['path']
if node['bcpc']['jolokia']['enable'] == true
  include_recipe 'bcpc-hadoop::jolokia'
end

zk_env_path = \
  "#{node['bcpc']['hadoop']['zookeeper']['conf_dir']}/zookeeper-env.sh"
template zk_env_path do
  auto_size = (node['memory']['total'].to_i *
                node['bcpc']['hadoop']['zookeeper']['xmx']['max_ratio']/1024)
  heap = [node['bcpc']['hadoop']['zookeeper']['xmx']['max_size'],
          auto_size.floor].min
  newsize = [(0.125*heap).ceil, 3072].min
  source 'zk_zookeeper-env.sh.erb'
  mode 0644
  variables(
    zk_jmx_port: node['bcpc']['hadoop']['zookeeper']['jmx']['port'],
    jmxtrans_agent_lib: node['bcpc']['jmxtrans_agent']['lib_file'],
    jmxtrans_agent_xml: node['bcpc']['hadoop']['jmxtrans_agent']['zookeeper']['xml'],
    auto_size: auto_size,
    heap: heap,
    newsize: newsize
  )
end

directory node['bcpc']['hadoop']['zookeeper']['data_dir'] do
  recursive true
  owner node['bcpc']['hadoop']['zookeeper']['owner']
  group node['bcpc']['hadoop']['zookeeper']['group']
  mode 0755
end

zkServer_path = "/usr/hdp/#{node['bcpc']['hadoop']['distribution']['active_release']}/zookeeper/bin/zkServer.sh"
template zkServer_path do
  source 'zk_zkServer.sh.erb'
end

link '/etc/init.d/zookeeper-server' do
  to "/usr/hdp/#{node['bcpc']['hadoop']['distribution']['active_release']}/zookeeper/etc/init.d/zookeeper-server"
  notifies :run, 'bash[kill zookeeper-org-apache-zookeeper-server-quorum-QuorumPeerMain]', :immediate
end

bash 'kill zookeeper-org-apache-zookeeper-server-quorum-QuorumPeerMain' do
  code 'pkill -u zookeeper -f org.apache.zookeeper.server.quorum.QuorumPeerMain'
  action :nothing
  returns [0, 1]
end

directory '/var/log/zookeeper/gc/' do
  user node['bcpc']['hadoop']['zookeeper']['owner']
  group node['bcpc']['hadoop']['zookeeper']['group']
  action :create
end

my_id_path = "#{node['bcpc']['hadoop']['zookeeper']['data_dir']}/myid"
bash 'init-zookeeper' do
  code 'service zookeeper-server init ' +
    "--myid=#{bcpc_8bit_node_number}"

  not_if do
    ::File.exists?(my_id_path)
  end

  # race immediate run of restarting ZK on initial stand-up
  subscribes :run, 'link[/etc/init.d/zookeeper-server]', :immediate
end

file my_id_path do
  content bcpc_8bit_node_number.to_s
  owner node['bcpc']['hadoop']['zookeeper']['owner']
  group node['bcpc']['hadoop']['zookeeper']['group']
  mode 0644
  # race immediate run of restarting ZK on initial stand-up
  subscribes :create, 'bash[init-zookeeper]', :immediate
end

service 'zookeeper-server' do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
end

locking_resource 'zookeeper-server' do
  process_identifier = 'org.apache.zookeeper.server.quorum.QuorumPeerMain'
  resource 'service[zookeeper-server]'
  process_pattern {command_string process_identifier
                   user node['bcpc']['hadoop']['zookeeper']['owner']
                   full_cmd true}
  perform :restart
  action :serialize_process
  subscribes :serialize_process, 'link[/etc/init.d/zookeeper-server]', :immediate
  subscribes :serialize_process, "template[#{node['bcpc']['hadoop']['zookeeper']['conf_dir']}/zoo.cfg]", :delayed
  subscribes :serialize_process, "template[#{zk_env_path}]", :delayed
  subscribes :serialize_process, "link[#{zkServer_path}]", :delayed
  subscribes :serialize_process, "file[#{my_id_path}]", :delayed
  subscribes :serialize_process, 'user_ulimit[zookeeper]', :delayed
  subscribes :serialize_process, 'bash[hdp-select zookeeper-server]', :delayed
  subscribes :serialize_process, 'log[jdk-version-changed]', :delayed
  subscribes :serialize_process, 'directory[/var/log/zookeeper/gc]', :delayed
end
