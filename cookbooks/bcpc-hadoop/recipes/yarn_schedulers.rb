hadoop_templates =
  %w{
   capacity-scheduler.xml
   fair-scheduler.xml
  }

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

template "/etc/hadoop/conf/capacity-scheduler.fresh.xml" do
  source "generic_site.xml.erb"
  mode 0644
  variables(:options => note[:bcpc][:hadoop][:scheduler][:capacity][:xml])
end
