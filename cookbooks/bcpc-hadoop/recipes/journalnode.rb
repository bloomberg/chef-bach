require 'base64'
include_recipe 'bcpc-hadoop::hadoop_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

hdprel=node[:bcpc][:hadoop][:distribution][:active_release]
hdppath="/usr/hdp/#{hdprel}"

%w{hadoop-hdfs-namenode hadoop-hdfs-journalnode}.each do |pkg|
  package hwx_pkg_str(pkg, hdprel) do
    action :install
  end
  hdp_select(pkg, hdprel)
end

[node[:bcpc][:hadoop][:mounts].first].each do |d|
  directory "/disk/#{d}/dfs/jn" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

  directory "/disk/#{d}/dfs/jn/#{node.chef_environment}" do
    owner "hdfs"
    group "hdfs"
    mode 0755
    action :create
    recursive true
  end

end

jndisk="/disk/#{node[:bcpc][:hadoop][:mounts][0]}"
jnfile="/dfs/jn/#{node.chef_environment}/current/VERSION"
jnfile2chk=jndisk + jnfile

if get_config("jn_txn_fmt") then
  file "#{Chef::Config[:file_cache_path]}/jn_fmt.tgz" do
    user "hdfs"
    group "hdfs"
    user 0644
    content Base64.decode64(get_config("jn_txn_fmt"))
    not_if{File.exists?(jnfile2chk)}
  end
end

bash "unpack-jn-fmt-image-to-disk-#{jndisk}" do
  user "root"
  cwd "#{jndisk}/dfs/"
  code "tar xzvf #{Chef::Config[:file_cache_path]}/jn_fmt.tgz;"
  notifies :restart, "service[hadoop-hdfs-journalnode]"
  notifies :run, "bash[change-ownership-for-jnfile]", :immediate
  only_if{not get_config("jn_txn_fmt").nil? and not 
  File.exists?(jnfile2chk)}
end

bash "change-ownership-for-jnfile" do
  user "root"
  cwd "#{jndisk}/dfs/jn"
  code "chown -R hdfs:hdfs #{node.chef_environment}"
  action :nothing
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
end
