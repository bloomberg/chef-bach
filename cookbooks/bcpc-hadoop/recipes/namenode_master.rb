require "base64"
require "digest"
require 'mixlib/shellout'

include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::namenode_queries'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

#
# Updating node attribuetes to copy namenode log files to centralized location (HDFS)
#
node.default['bcpc']['hadoop']['copylog']['namenode_master'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.log",
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['namenode_master_out'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.out",
    'docopy' => true
}

# shortcut to the desired HDFS command version
hdfs_cmd = "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-hdfs/bin/hdfs"

%w{hadoop-hdfs-namenode hadoop-hdfs-zkfc hadoop-mapreduce}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
    action :install
  end
end

hdp_select('hadoop-hdfs-namenode', node[:bcpc][:hadoop][:distribution][:active_release])
hdp_select('hadoop-client', node[:bcpc][:hadoop][:distribution][:active_release])

# need to ensure hdfs user is in hadoop and hdfs
# groups. Packages will not add hdfs if it
# is already created at install time (e.g. if
# machine is using LDAP for users).

# Create all the resources to add them in resource collection
node[:bcpc][:hadoop][:os][:group].keys.each do |group_name|
  node[:bcpc][:hadoop][:os][:group][group_name][:members].each do|user_name|
    user user_name do
      home "/var/lib/hadoop-#{user_name}"
      shell '/bin/bash'
      system true
      action :create
      not_if { user_exists?(user_name) }
    end
  end

  group group_name do
    append true
    members node[:bcpc][:hadoop][:os][:group][group_name][:members]
    action :nothing
  end
end
  
# Take action on each group resource based on its existence 
ruby_block 'create_or_manage_groups' do
  block do
    node[:bcpc][:hadoop][:os][:group].keys.each do |group_name|
      res = run_context.resource_collection.find("group[#{group_name}]")
      res.run_action(get_group_action(group_name))
    end
  end
end

directory "/var/log/hadoop-hdfs/gc/" do
  user "hdfs"
  group "hdfs"
  action :create
  notifies :restart, "service[hadoop-hdfs-namenode]", :delayed
end

user_ulimit "hdfs" do
  filehandle_limit 32769
  process_limit 65536
end

node[:bcpc][:hadoop][:mounts].each do |d|
  directory "/disk/#{d}/dfs/nn" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

  execute "fixup nn owner" do
    command "chown -Rf hdfs:hdfs /disk/#{d}/dfs"
    only_if { Etc.getpwuid(File.stat("/disk/#{d}/dfs/").uid).name != "hdfs" }
  end
end

configure_kerberos 'namenode_kerb' do
  service_name 'namenode'
end

bash "format namenode" do
  code "#{hdfs_cmd} namenode -format -nonInteractive -force"
  user "hdfs"
  action :run
  creates "/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/nn/current/VERSION"
  not_if { node[:bcpc][:hadoop][:mounts].any? { |d| File.exists?("/disk/#{d}/dfs/nn/current/VERSION") } }
end

bash "format-zk-hdfs-ha" do
  code "yes | #{hdfs_cmd} zkfc -formatZK"
  action :run
  user "hdfs"
  notifies :restart, "service[hadoop-hdfs-namenode]", :delayed
  zks = node[:bcpc][:hadoop][:zookeeper][:servers].map{|zkh| "#{float_host(zkh[:hostname])}:#{node[:bcpc][:hadoop][:zookeeper][:port]}"}.join(",")
  not_if { znode_exists?("/hadoop-ha/#{node.chef_environment}", zks) }
end

# Work around Hortonworks Case #00071808
link "/usr/hdp/current/hadoop-hdfs-zkfc" do
  to "/usr/hdp/current/hadoop-hdfs-namenode"
end

link "/etc/init.d/hadoop-hdfs-zkfc" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-hdfs/etc/init.d/hadoop-hdfs-zkfc"
  notifies :run, 'bash[kill hdfs-zkfc]', :immediate
end

bash "kill hdfs-zkfc" do
  code "pkill -u hdfs -f zkfc"
  action :nothing
  returns [0, 1]
end

service "hadoop-hdfs-zkfc" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "link[/etc/init.d/hadoop-hdfs-zkfc]", :immediate
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site_HA.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
end

# need to bring the namenode down to initialize shared edits
service "bring hadoop-hdfs-namenode down for shared edits and HA transition" do
  service_name "hadoop-hdfs-namenode"
  action :stop
  supports :status => true
  notifies :run, "bash[initialize shared edits]", :immediately
  only_if { node[:bcpc][:hadoop][:mounts].all? { |d| not File.exists?("/disk/#{d}/dfs/jn/#{node.chef_environment}/current/VERSION") } }
end

bash "initialize shared edits" do
  code "#{hdfs_cmd} namenode -initializeSharedEdits"
  user "hdfs"
  action :nothing
end

link "/etc/init.d/hadoop-hdfs-namenode" do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hadoop-hdfs/etc/init.d/hadoop-hdfs-namenode"
  notifies :run, 'bash[kill hdfs-namenode]', :immediate
end

bash "kill hdfs-namenode" do
  code "pkill -u hdfs -f namenode"
  action :nothing
  returns [0, 1]
end

service "hadoop-hdfs-namenode" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  service_name "hadoop-hdfs-namenode"
  subscribes :restart, "link[/etc/init.d/hadoop-hdfs-namenode]", :immediate
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-metrics2.properties]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site_HA.xml]", :delayed
  subscribes :restart, "file[/etc/hadoop/conf/ldap-conn-pass.txt]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/topology]", :delayed
  subscribes :restart, "user_ulimit[hdfs]", :delayed
  subscribes :restart, "bash[initialize-shared-edits]", :immediately
  subscribes :restart, "bash[hdp-select hadoop-hdfs-namenode]", :delayed
end

ruby_block "create-format-UUID-File" do
  block do
    Dir.chdir("/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/") do
      system("tar czvf #{Chef::Config[:file_cache_path]}/jn_fmt.tgz jn/#{node.chef_environment}/current/VERSION")
    end
  end
  action :run
  only_if { File.exists?("/disk/#{node[:bcpc][:hadoop][:mounts][0]}/dfs/jn/#{node.chef_environment}/current/VERSION") }
end

ruby_block "upload-format-UUID-File" do
  block do
    cmdStrLayVersn = "zgrep -a -i layoutVersion #{Chef::Config[:file_cache_path]}/jn_fmt.tgz|uniq|cut -d'=' -f2"
    node_layout_version = 0
    if node[:bcpc][:hadoop][:hdfs].key?('layoutVersion')
      node_layout_version = node[:bcpc][:hadoop][:hdfs][:layoutVersion]
    end

    cmd = Mixlib::ShellOut.new(cmdStrLayVersn, :timeout => 10).run_command
    cmd.error!
    Chef::Log.debug("layoutVersion stored in node is : #{node_layout_version}")
    Chef::Log.debug("layoutVersion stored in the file is #{cmd.stdout.to_i}")

    if ( get_config("jn_txn_fmt").nil? ) || ( cmd.stdout.to_i < node_layout_version )
      make_config!("jn_txn_fmt", Base64.encode64(IO.read("#{Chef::Config[:file_cache_path]}/jn_fmt.tgz")));
      node.set[:bcpc][:hadoop][:hdfs][:layoutVersion] = cmd.stdout.to_i
      node.save
    elsif cmd.stdout.to_i > node_layout_version
      raise("New HDFS layoutVersion is lower than old HDFS layoutVersion: #{cmd.stdout.to_i} > #{node_layout_version}")
    end
  end
  action :run
  ignore_failure true
  only_if { File.exists?("#{Chef::Config[:file_cache_path]}/jn_fmt.tgz") }
end

bash "reload hdfs nodes" do
  code "#{hdfs_cmd} dfsadmin -refreshNodes"
  user "hdfs"
  action :nothing
  subscribes :run, "template[/etc/hadoop/conf/dfs.exclude]", :delayed
end

###
# We only want to execute this once, as it is setup of dirs within HDFS.
# We'd prefer to do it after all nodes are members of the HDFS system
#
bash "create-hdfs-temp" do
  code "#{hdfs_cmd} dfs -mkdir /tmp; #{hdfs_cmd} dfs -chmod -R 1777 /tmp"
  user "hdfs"
  not_if "sudo -u hdfs #{hdfs_cmd} dfs -test -d /tmp"
end

bash "create-hdfs-applogs" do
  code "#{hdfs_cmd} dfs -mkdir /app-logs; #{hdfs_cmd} dfs -chmod -R 1777 /app-logs; #{hdfs_cmd} dfs -chown yarn /app-logs"
  user "hdfs"
  not_if "sudo -u hdfs #{hdfs_cmd} dfs -test -d /app-logs"
end

bash "create-hdfs-user" do
  code "#{hdfs_cmd} dfs -mkdir /user; #{hdfs_cmd} dfs -chmod -R 0755 /user"
  user "hdfs"
  not_if "sudo -u hdfs #{hdfs_cmd} dfs -test -d /user"
end
