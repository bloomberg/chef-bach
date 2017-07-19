include_recipe 'bcpc-hadoop::hadoop_config'
require "base64"
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

#
# Updating node attributes to copy namenode log files to centralized location (HDFS)
#
node.default['bcpc']['hadoop']['copylog']['namenode_standby'] = {
    'logfile' => "/var/log/hadoop-hdfs/hadoop-hdfs-namenode-#{node.hostname}.log",
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['namenode_standby_out'] = {
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

directory '/var/log/hadoop-hdfs/gc/' do
  user 'hdfs'
  group 'hdfs'
  action :create
end

user_ulimit 'hdfs' do
  filehandle_limit 65536
  process_limit 65536
end

ruby_block 'create-namenode-directories' do
  block do
    node.run_state[:bcpc_hadoop_disks][:mounts].each do |d|
      Chef::Resource::Directory.new("/disk/#{d}/dfs/nn",
                                    node.run_context).tap do |dd|
        dd.owner "hdfs"
        dd.group "hdfs"
        dd.mode 0755
        dd.recursive true
        dd.run_action :create
      end

      if Etc.getpwuid(File.stat("/disk/#{d}/dfs/").uid).name != 'hdfs'
        Chef::Resource::Execute.new('fixup nn owner',
                                    node.run_context).tap do |ee|
          ee.command "chown -Rf hdfs:hdfs /disk/#{d}/dfs/"
          ee.run_action(:run)
        end
      end
    end
  end
end

configure_kerberos 'namenode_spnego' do
  service_name 'spnego'
end

configure_kerberos 'namenode_kerb' do
  service_name 'namenode'
end

if node['bcpc']['hadoop']['hdfs']['HA'] == true then
  bash "#{hdfs_cmd} namenode -bootstrapStandby -force -nonInteractive" do
    code "#{hdfs_cmd} namenode -bootstrapStandby -force -nonInteractive"
    user "hdfs"
    cwd  "/var/lib/hadoop-hdfs"
    action :run
    not_if { Dir.glob('/disk/*/dfs/nn/current').any? }
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
    action [:enable, :start]
    supports :status => true, :restart => true, :reload => false
    subscribes :restart, "link[/etc/init.d/hadoop-hdfs-zkfc]", :immediate
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
    subscribes :restart, "log[jdk-version-changed]", :delayed
  end

  link "/etc/init.d/hadoop-hdfs-namenode" do
    to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:release]}/hadoop-hdfs/etc/init.d/hadoop-hdfs-namenode"
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
    subscribes :restart, "link[/etc/init.d/hadoop-hdfs-namenode]", :immediate
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hadoop-metrics2.properties]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hdfs-policy.xml]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
    subscribes :restart, "template[/etc/hadoop/conf/topology]", :delayed
    subscribes :restart, "user_ulimit[hdfs]", :delayed
    subscribes :restart, "directory[/var/log/hadoop-hdfs/gc/]", :delayed
    subscribes :restart, "file[/etc/hadoop/conf/ldap-conn-pass.txt]", :delayed
    subscribes :restart, "bash[hdp-select hadoop-hdfs-namenode]", :delayed
    subscribes :restart, "log[jdk-version-changed]", :delayed
    subscribes :restart, node['bcpc']['hadoop']['jmxtrans_agent']['namenode']['xml'], :delayed
  end
else
  Chef::Log.info "Not running standby namenode services yet -- HA disabled!"
  service "hadoop-hdfs-zkfc" do
    action [:disable, :stop]
  end
  service "hadoop-hdfs-namenode" do
    action [:disable, :stop]
  end
end

bash "reload hdfs nodes" do
  code "#{hdfs_cmd} dfsadmin -refreshNodes"
  user "hdfs"
  action :nothing
  subscribes :run, "template[/etc/hadoop/conf/dfs.exclude]", :delayed
end
