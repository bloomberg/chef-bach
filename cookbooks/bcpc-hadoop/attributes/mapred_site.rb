mapred_site_values = node[:bcpc][:hadoop][:mapreduce][:site_xml]

mapred_site_generated_values =
{
   
}

hs_hosts = node[:bcpc][:hadoop][:hs_hosts]
if not hs_hosts.empty?
  hs_properties =
    {
     'mapreduce.jobhistory.address' =>
       "#{float_host(@hs_hosts.map{|i| i[:hostname] }.sort.first)}:10020",
     
     'mapreduce.jobhistory.webapp.address' =>
       "#{float_host(@hs_hosts.map{|i| i[:hostname] }.sort.first)}:19888",
    }
  mapred_site_generated_values.merge!(hs_properties)
end

complete_mapred_site_hash =
  mapred_site_generated_values.merge(mapred_site_values)

template "/etc/hadoop/conf/mapred-site.xml" do
  source "hdp_mapred-site.xml.erb"
  mode 0644
  variables(:nn_hosts => node[:bcpc][:hadoop][:nn_hosts],
            :zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers],
            :jn_hosts => node[:bcpc][:hadoop][:jn_hosts],
            :rm_hosts => node[:bcpc][:hadoop][:rm_hosts],
            :dn_hosts => node[:bcpc][:hadoop][:dn_hosts],
            :hs_hosts => node[:bcpc][:hadoop][:hs_hosts],
            :mounts => node[:bcpc][:hadoop][:mounts])
end

template "/etc/hadoop/conf/mapred-site.fresh.xml" do
  source "generic_site.xml.erb"
  mode 0644
  variables(:options => complete_mapred_site_hash)
end
