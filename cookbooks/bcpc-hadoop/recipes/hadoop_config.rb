directory "/etc/hadoop/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

bash "update-hadoop-conf-alternatives" do
  code %Q{
    update-alternatives --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.#{node.chef_environment} 50
    update-alternatives --set hadoop-conf /etc/hadoop/conf.#{node.chef_environment}
  }
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

hadoop_conf_files = %w{capacity-scheduler.xml
   core-site.xml
   fair-scheduler.xml
   hadoop-metrics2.properties
   hadoop-policy.xml
   hdfs-site.xml
   log4j.properties
   mapred-site.xml
   slaves
   ssl-client.xml
   ssl-server.xml
   yarn-site.xml
   yarn.exclude
   dfs.exclude
}
node[:bcpc][:hadoop][:hdfs][:HA] == true and hadoop_conf_files.insert(-1,"hdfs-site_HA.xml")

hadoop_conf_files.each do |t|
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

template "/etc/hadoop/conf/yarn-env.sh" do
  source "hdp_yarn-env.sh.erb"
  mode 0555
  variables(
   :yarn_jute_maxbuffer => node['bcpc']['hadoop']['yarn']['opts']['jute_buffer'],
   :nm_jmx_port => node[:bcpc][:hadoop][:nodemanager][:jmx][:port],
   :rm_jmx_port => node[:bcpc][:hadoop][:resourcemanager][:jmx][:port]
  )
end  
