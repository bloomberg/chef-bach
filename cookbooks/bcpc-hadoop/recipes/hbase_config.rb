# Cookbook Name : bcpc-hadoop
# Recipe Name : hbase_config
# Description : To setup habse related configuration only

directory "/etc/hbase/conf.#{node.chef_environment}" do
  owner "root"
  group "root"
  mode 00755
  action :create
  recursive true
end

bash "update-hbase-conf-alternatives" do
  code %Q{
    update-alternatives --install /etc/hbase/conf hbase-conf /etc/hbase/conf.#{node.chef_environment} 50
    update-alternatives --set hbase-conf /etc/hbase/conf.#{node.chef_environment}
  }
end

if get_nodes_for("powerdns", "bcpc").length > 0
 dns_server = node[:bcpc][:management][:vip]
else
 dns_server = node[:bcpc][:dns_servers][0]
end

%w{hadoop-metrics.properties
   hbase-env.sh
   hbase-policy.xml
   hbase-site.xml
   log4j.properties
   regionservers}.each do |t|
   template "/etc/hbase/conf/#{t}" do
     source "hb_#{t}.erb"
     mode 0644
     variables(:nn_hosts => node[:bcpc][:hadoop][:nn_hosts],
               :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
               :jn_hosts => node[:bcpc][:hadoop][:jn_hosts],
               :rs_hosts => node[:bcpc][:hadoop][:rs_hosts],
               :master_hosts => node[:bcpc][:hadoop][:hb_hosts],
               :mounts => node[:bcpc][:hadoop][:mounts],
               :hbm_jmx_port => node[:bcpc][:hadoop][:hbase_master][:jmx][:port],
               :hbrs_jmx_port => node[:bcpc][:hadoop][:hbase_rs][:jmx][:port],
               :dns_server => dns_server
     )
  end
end

if node[:bcpc][:hadoop][:kerberos][:enable] == true then 
  %w{
    hbase-client.jaas
    hbase-server.jaas
    regionserver.jaas}.each do |t|
    template "/etc/hbase/conf/#{t}" do
      source "hb_#{t}.erb"
      mode 0644
    end
  end
end 
