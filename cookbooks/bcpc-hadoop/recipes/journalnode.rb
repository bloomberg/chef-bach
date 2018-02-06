require 'base64'
include_recipe 'bcpc-hadoop::hadoop_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)
include_recipe 'bcpc-hadoop::journalnode_queries'

hdprel=node[:bcpc][:hadoop][:distribution][:active_release]
hdppath="/usr/hdp/#{hdprel}"

# Setup JMXTrans information
node.default['jmxtrans'].tap do |jmxtrans|
  jmxtrans['servers'] = [
                          {
                          'type': 'journalnode',
                          'service': 'hadoop-hdfs-journalnode',
                          'service_cmd': 'org.apache.hadoop.hdfs.qjournal.server.JournalNode'
                          }
                        ]
  jmxtrans['default_queries']['journalnode'] =
    [
      {
        'obj': 'Hadoop:service=JournalNode,name=RpcDetailedActivityForPort*',
        'result_alias': 'DetailedRPCActivity',
        'attr': []
      },
      {
        'obj': 'Hadoop:service=JournalNode,name=RpcActivityForPort8485',
        'result_alias': 'RPCActivity',
        'attr': []
      },
      {
        'obj': 'Hadoop:service=JournalNode,name=UgiMetrics',
        'result_alias': 'UgiMetrics',
        'attr': []
      },
      {
        'obj': 'Hadoop:service=JournalNode,name=Journal-*',
        'result_alias': 'JNActivity',
        'attr': []
      }
    ]
    
end

%w{hadoop-hdfs-namenode hadoop-hdfs-journalnode}.each do |pkg|
  package hwx_pkg_str(pkg, hdprel) do
    action :install
  end
  hdp_select(pkg, hdprel)
end

ruby_block 'setup-jn-data' do
  block do
    jndisk="/disk/#{node.run_state[:bcpc_hadoop_disks][:mounts][0]}"
    jnfile="/dfs/jn/#{node.chef_environment}/current/VERSION"
    jncurrent="/dfs/jn/#{node.chef_environment}/current"
    jnfile2chk=jndisk + jnfile

    Chef::Resource::Directory.new("#{jndisk}/dfs/jn/",
                                  node.run_context).tap do |dd|
      dd.owner 'hdfs'
      dd.group 'hdfs'
      dd.mode 0755
      dd.recursive true
      dd.run_action :create
    end

    Chef::Resource::Directory.new("#{jndisk}/dfs/jn/#{node.chef_environment}",
                                  node.run_context).tap do |dd|
      dd.owner 'hdfs'
      dd.group 'hdfs'
      dd.mode 0755
      dd.recursive true
      dd.run_action :create
    end

    Chef::Resource::Log.new('jn_txn_fmt_path',
                            run_context).tap do |ll|
      ll.message("JN txn fmt file checked: #{jnfile2chk}")
      ll.level(:info)
      ll.run_action(:write)
    end

    if get_config('jn_txn_fmt') && !File.exists?(jnfile2chk) then
      Chef::Resource::File.new("#{Chef::Config[:file_cache_path]}/jn_fmt.tgz",
                               node.run_context).tap do |ff|
        ff.user 'hdfs'
        ff.group 'hdfs'
        ff.mode 0644
        ff.content Base64.decode64(get_config('jn_txn_fmt'))
        ff.run_action(:create)
      end

      Chef::Resource::Bash.new("unpack-jn-fmt-image-to-disk-#{jndisk}",
                               node.run_context).tap do |bb|
        bb.user "root"
        bb.cwd "#{jndisk}/dfs/"
        bb.code "tar xzvf #{Chef::Config[:file_cache_path]}/jn_fmt.tgz"
        bb.run_action(:run)
      end

      Chef::Resource::Bash.new('change-ownership-for-jnfile',
                               node.run_context).tap do |bb|
        bb.user 'root'
        bb.cwd "#{jndisk}/dfs/jn"
        bb.code "chown -R hdfs:hdfs #{node.chef_environment}"
        bb.run_action :run
      end

      #
      # Our dynamic resources don't exist in the resource collection, so
      # we have to have the ruby_block resource itself handle
      # notifications.
      #
      self.notifies :restart, 'service[hadoop-hdfs-journalnode]'
      self.resolve_notification_references
    end

    if File.exists?(jnfile2chk)
      Chef::Resource::Directory.new("#{jndisk}#{jncurrent}/paxos",
                                    node.run_context).tap do |dd|
        dd.owner 'hdfs'
        dd.group 'hdfs'
        dd.mode 0755
        dd.recursive true
        dd.run_action :create
      end
    end
  end
end

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

link "/etc/init.d/hadoop-hdfs-journalnode" do
  to "#{hdppath}/hadoop-hdfs/etc/init.d/hadoop-hdfs-journalnode"
  notifies :run, 'bash[kill hdfs-journalnode]', :immediate
end

configure_kerberos 'journalnode_spnego' do
  service_name 'spnego'
end

configure_kerberos 'namenode_kerb' do
  service_name 'namenode'
end

configure_kerberos 'journalnode_kerb' do
  service_name 'journalnode'
end

bash "kill hdfs-journalnode" do
  code "pkill -u hdfs -f journalnode"
  action :nothing
  returns [0, 1]
end

jnKeytab = node[:bcpc][:hadoop][:kerberos][:data][:journalnode][:keytab]
nnKeytab = node[:bcpc][:hadoop][:kerberos][:data][:namenode][:keytab]
keyTabDir = node[:bcpc][:hadoop][:kerberos][:keytab][:dir]

service "hadoop-hdfs-journalnode" do
  action [:start, :enable]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "link[/etc/init.d/hadoop-hdfs-journalnode]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site_HA.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "file[#{keyTabDir}/#{jnKeytab}]", :delayed
  subscribes :restart, "file[#{keyTabDir}/#{nnKeytab}]", :delayed
  subscribes :restart, "log[jdk-version-changed]", :delayed
end
