include_recipe 'bcpc::chef_poise_install'
include_recipe 'bcpc-hadoop::hadoop_config'
include_recipe 'bcpc-hadoop::hive_config'

::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

hdp_select_pkgs = %w(hadoop-yarn-nodemanager hadoop-hdfs-datanode hadoop-client)

hdp_pkg_strs = (hdp_select_pkgs + %w(
  hadoop-mapreduce
  sqoop
  hadooplzo
  hadooplzo-native
)).map do |p|
  hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release])
end

[
  hdp_pkg_strs,
  'mysql-connector-java',
  'cgroup-bin'
].flatten.each do |pkg|
  package pkg do
    action :install
  end
end

(hdp_select_pkgs + ['sqoop-client', 'sqoop-server']).each do |pkg|
  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

user_ulimit 'root' do
  filehandle_limit 65_536
  process_limit 65_536
end

user_ulimit 'hdfs' do
  filehandle_limit 65_536
  process_limit 65_536
end

# Intentionally hobble jmxtrans to ensure it doesn't destroy the system
user_ulimit 'jmxtrans' do
  filehandle_limit 1024
  process_limit 1024
end

user_ulimit 'mapred' do
  filehandle_limit 65_536
  process_limit 65_536
end

user_ulimit 'yarn' do
  filehandle_limit 65_536
  process_limit 65_536
end

configure_kerberos 'datanode_spnego' do
  service_name 'spnego'
end

configure_kerberos 'datanode_kerb' do
  service_name 'datanode'
end

configure_kerberos 'nodemanager_spnego' do
  service_name 'spnego'
end

configure_kerberos 'nodemanager_kerb' do
  service_name 'nodemanager'
end

configure_kerberos 'mapred_spnego' do
  service_name 'spnego'
end

configure_kerberos 'mapred_kerb' do
  service_name 'historyserver'
end
# need to ensure hdfs user is in hadoop and hdfs
# groups. Packages will not add hdfs if it
# is already created at install time (e.g. if
# machine is using LDAP for users).
# Similarly, yarn needs to be in the hadoop
# group to run the LCE and in the mapred group
# for log aggregation

# Create all the resources to add them in resource collection
node[:bcpc][:hadoop][:os][:group].keys.each do |group_name|
  node[:bcpc][:hadoop][:os][:group][group_name][:members].each do |user_name|
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

directory '/var/run/hadoop-hdfs' do
  owner 'hdfs'
  group 'root'
end

directory '/var/log/hadoop-hdfs/gc' do
  owner 'hdfs'
  group 'hdfs'
end

directory '/sys/fs/cgroup/cpu/hadoop-yarn' do
  owner 'yarn'
  group 'yarn'
  mode '0755'
  action :create
end

execute 'chown hadoop-yarn cgroup tree to yarn' do
  command 'chown -Rf yarn:yarn /sys/fs/cgroup/cpu/hadoop-yarn'
  action :run
end

link '/etc/init.d/hadoop-hdfs-datanode' do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}"\
     '/hadoop-hdfs/etc/init.d/hadoop-hdfs-datanode'
  notifies :run, 'bash[kill hdfs-hdfs-datanode]', :immediate
end

bash 'kill hdfs-hdfs-datanode' do
  code 'pkill -u hdfs -f hdfs-datanode'
  action :nothing
  returns [0, 1]
end

# Install YARN Bits
template '/etc/hadoop/conf/container-executor.cfg' do
  source 'hdp_container-executor.cfg.erb'
  owner 'root'
  group 'yarn'
  mode '0400'
  variables lazy { { mounts: node.run_state['bcpc_hadoop_disks']['mounts'] } }
  action :create
  notifies :run, 'bash[verify-container-executor]', :immediate
end

bash 'verify-container-executor' do
  code "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}"\
       '/hadoop-yarn/bin/container-executor --checksetup'
  user 'yarn'
  group 'yarn'
  action :nothing
  only_if do
    File.exist?('/usr/hdp/'\
                "#{node[:bcpc][:hadoop][:distribution][:active_release]}"\
                '/hadoop-yarn/bin/container-executor')
  end
end

# Install Sqoop Bits
template '/etc/sqoop/conf/sqoop-env.sh' do
  source 'sq_sqoop-env.sh.erb'
  mode '0444'
  action :create
end

# Install Hive Bits
# workaround for hcatalog dpkg not creating the hcat user it requires
user 'hcat' do
  username 'hcat'
  system true
  shell '/bin/bash'
  home '/usr/lib/hcatalog'
  supports manage_home: false
  not_if { user_exists? 'hcat' }
end

distrib_release = node[:bcpc][:hadoop][:distribution][:release]
package hwx_pkg_str('hive-hcatalog', distrib_release) do
  action :install
end

hdp_select('hive-webhcat', node[:bcpc][:hadoop][:distribution][:active_release])

link '/usr/hdp/current/hive-metastore/lib/mysql-connector-java.jar' do
  to '/usr/share/java/mysql-connector-java.jar'
end

link '/usr/hdp/current/hive-server2/lib/mysql-connector-java.jar' do
  to '/usr/share/java/mysql-connector-java.jar'
end

# Setup datanode and nodemanager bits
ruby_block 'count-mounts' do
  block do
    mount_count =
      node.run_state['bcpc_hadoop_disks']['mounts'].length rescue 0
    tolerated_failures =
      node[:bcpc][:hadoop][:hdfs][:failed_volumes_tolerated]
    if mount_count <= tolerated_failures
      Chef::Application.fatal!('You have fewer available hadoop disks than ' \
                               'hdfs tolerated failures '\
                               "(#{tolerated_failures})! " \
                               'See comments of HDFS-4442.')
    end
  end
end

link '/etc/init.d/hadoop-yarn-nodemanager' do
  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}"\
     '/hadoop-yarn/etc/init.d/hadoop-yarn-nodemanager'
  notifies :run, 'bash[kill yarn-yarn-nodemanager]', :immediate
end

bash 'kill yarn-yarn-nodemanager' do
  code 'pkill -u yarn -f yarn-nodemanager'
  action :nothing
  returns [0, 1]
end

# Build nodes for HDFS storage
ruby_block 'create-hdfs-directories' do
  block do
    node.run_state['bcpc_hadoop_disks']['mounts'].each do |i|
      Chef::Resource::Directory.new("/disk/#{i}/dfs",
                                    node.run_context).tap do |dd|
        dd.owner 'hdfs'
        dd.group 'hdfs'
        dd.mode '0700'
        dd.run_action :create
      end

      Chef::Resource::Directory.new("/disk/#{i}/dfs",
                                    node.run_context).tap do |dd|
        dd.owner 'hdfs'
        dd.group 'hdfs'
        dd.mode '0700'
        dd.run_action :create
      end

      Chef::Resource::Directory.new("/disk/#{i}/yarn/",
                                    node.run_context).tap do |dd|
        dd.owner 'yarn'
        dd.group 'yarn'
        dd.mode '0755'
        dd.run_action :create
      end

      %w(mapred-local local logs).each do |d|
        Chef::Resource::Directory.new("/disk/#{i}/yarn/#{d}",
                                      node.run_context).tap do |dd|
          dd.owner 'yarn'
          dd.group 'hadoop'
          dd.mode '0755'
          dd.run_action :create
        end
      end
    end
  end
end

service 'hadoop-hdfs-datanode' do
  supports status: true, restart: true, reload: false
  action [:enable, :start]
end

locking_resource 'hadoop-hdfs-datanode-restart' do
  resource 'service[hadoop-hdfs-datanode]'
  process_pattern do
    command_string 'datanode'
    user 'hdfs'
    full_cmd true
  end
  perform :restart
  action :serialize_process
  subscribes :serialize, 'template[/etc/hadoop/conf/hdfs-site.xml]', :delayed
  subscribes :serialize,
             'template[/etc/hadoop/conf/hadoop-metrics2.properties]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/hadoop-env.sh]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/topology]', :delayed
  subscribes :serialize, 'user_ulimit[hdfs]', :delayed
  subscribes :serialize, 'user_ulimit[root]', :delayed
  subscribes :serialize, 'bash[hdp-select hadoop-hdfs-datanode]', :delayed
  subscribes :serialize, 'log[jdk-version-changed]', :delayed
  subscribes :serialize, 'link[/etc/init.d/hadoop-hdfs-datanode]', :delayed
  jmx_xml = node['bcpc']['hadoop']['jmxtrans_agent']['datanode']['xml']
  subscribes :serialize, jmx_xml, :delayed
end

service 'hadoop-yarn-nodemanager' do
  supports status: true, restart: true, reload: false
  action [:enable, :start]
end

locking_resource 'hadoop-hdfs-nodemanager-restart' do
  resource 'service[hadoop-yarn-nodemanager]'
  process_pattern do
    command_string 'nodemanager'
    user 'yarn'
    full_cmd true
  end
  perform :restart
  action :serialize_process
  subscribes :serialize, 'link[/etc/init.d/hadoop-yarn-nodemanager]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/container-executor.cfg]'
  subscribes :serialize, 'template[/etc/hadoop/conf/hadoop-env.sh]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/yarn-env.sh]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/yarn-site.xml]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/hdfs-site.xml]', :delayed
  subscribes :serialize, 'template[/etc/hadoop/conf/mapred-site.xml]', :delayed
  subscribes :serialize, 'bash[hdp-select hadoop-yarn-nodemanager]', :delayed
  subscribes :serialize, 'user_ulimit[yarn]', :delayed
  subscribes :serialize, 'log[jdk-version-changed]', :delayed
  jmx_xml = node['bcpc']['hadoop']['jmxtrans_agent']['nodemanager']['xml']
  subscribes :serialize, jmx_xml, :delayed
end
