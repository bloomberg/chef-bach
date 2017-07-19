directory "/etc/hadoop/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

bash "update-hadoop-conf-alternatives" do
  code "update-alternatives --install /etc/hadoop/conf hadoop-conf " +
    "/etc/hadoop/conf.#{node.chef_environment} 50\n" +
    "update-alternatives --set hadoop-conf " +
    "/etc/hadoop/conf.#{node.chef_environment}\n"
end

if node[:bcpc][:hadoop][:hdfs][:ldap][:integration]
  ldap_pwd =
    if node[:bcpc][:hadoop][:hdfs][:ldap][:password].nil?
      get_config('password', 'ldap', 'os')
    else
      node[:bcpc][:hadoop][:hdfs][:ldap][:password]
    end

  file "/etc/hadoop/conf/ldap-conn-pass.txt" do
    content "#{ldap_pwd}"
    mode 0444
    owner "hdfs"
    group "hadoop"
    sensitive true
  end
end

file '/etc/hadoop/conf/slaves' do
  mode 0644
  content "localhost\n" +
    node[:bcpc][:hadoop][:dn_hosts].map{ |h| float_host(h) }.join("\n")
end

# These files have no <%= %> blocks.
hadoop_non_templates =
  %w{
   hadoop-metrics2.properties
   hadoop-policy.xml
   log4j.properties
   ssl-client.xml
   ssl-server.xml
   dfs.exclude
  }

hadoop_non_templates.each do |t|
  template "/etc/hadoop/conf/#{t}" do
    source "hdp_#{t}.erb"
    mode 0644
  end
end

template "/etc/hadoop/conf/topology" do
  source "#{node["bcpc"]["hadoop"]["topology"]["script"]}.erb"
  if node["bcpc"]["hadoop"]["topology"]["cookbook"]
    cookbook node["bcpc"]["hadoop"]["topology"]["cookbook"]
  end
  mode 0655
end

template "/etc/hadoop/conf/hadoop-env.sh" do
  source "hdp_hadoop-env.sh.erb"
  mode 0555
  variables(
    :nn_jmx_port => node['bcpc']['hadoop']['namenode']['jmx']['port'],
    :dn_jmx_port => node['bcpc']['hadoop']['datanode']['jmx']['port'],
    :jn_jmx_port => node['bcpc']['hadoop']['journalnode']['jmx']['port']
  )
end

include_recipe 'bcpc-hadoop::core_site'
include_recipe 'bcpc-hadoop::hdfs_site'
include_recipe 'bcpc-hadoop::mapred_site'
include_recipe 'bcpc-hadoop::yarn_config'
include_recipe 'bcpc-hadoop::jmxtrans_agent'
