directory "/etc/hadoop/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

bash "update-hadoop-conf-alternatives" do
  code(%Q{
    update-alternatives --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.#{node.chef_environment} 50
    update-alternatives --set hadoop-conf /etc/hadoop/conf.#{node.chef_environment}
  })
end
if ( node[:bcpc][:hadoop][:hdfs][:ldap][:integration] == true )

  ldap_pwd = ( node[:bcpc][:hadoop][:hdfs][:ldap][:password].nil? ? get_config('password', 'ldap', 'os') : node[:bcpc][:hadoop][:hdfs][:ldap][:password] )

  file "/etc/hadoop/conf/ldap-conn-pass.txt" do
    content "#{ldap_pwd}"
    mode 0444
    owner "hdfs"
    group "hadoop"
    sensitive true
  end
end

hadoop_templates =
  %w{
   capacity-scheduler.xml
   fair-scheduler.xml
   mapred-site.xml
   slaves
  }

if node[:bcpc][:hadoop][:hdfs][:HA]
  hadoop_templates.insert(-1,"hdfs-site_HA.xml")
end

hadoop_templates.each do |t|
   template "/etc/hadoop/conf/#{t}" do
     source "hdp_#{t}.erb"
     mode 0644
     variables(:nn_hosts => node[:bcpc][:hadoop][:nn_hosts],
               :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
               :jn_hosts => node[:bcpc][:hadoop][:jn_hosts],
               :rm_hosts => node[:bcpc][:hadoop][:rm_hosts],
               :dn_hosts => node[:bcpc][:hadoop][:dn_hosts],
               :hs_hosts => node[:bcpc][:hadoop][:hs_hosts],
               :mounts => node[:bcpc][:hadoop][:mounts])
   end
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
  cookbook node["bcpc"]["hadoop"]["topology"]["cookbook"] if node["bcpc"]["hadoop"]["topology"]["cookbook"]
  mode 0655
end

template "/etc/hadoop/conf/hadoop-env.sh" do
  source "hdp_hadoop-env.sh.erb"
  mode 0555
  variables(
    :nn_jmx_port => node[:bcpc][:hadoop][:namenode][:jmx][:port],
    :dn_jmx_port => node[:bcpc][:hadoop][:datanode][:jmx][:port]
  )
end

include_recipe 'bcpc-hadoop::core_site'
include_recipe 'bcpc-hadoop::yarn_config'
include_recipe 'bcpc-hadoop::hdfs_site'
