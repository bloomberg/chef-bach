mapred_site_values = node[:bcpc][:hadoop][:mapreduce][:site_xml]

mapred_site_generated_values =
{
   
}

hs_hosts = node[:bcpc][:hadoop][:hs_hosts]
if not hs_hosts.empty?
  hs_properties =
    {
     'mapreduce.jobhistory.address' =>
       "#{float_host(hs_hosts.map{|i| i[:hostname] }.sort.first)}:10020",
     
     'mapreduce.jobhistory.webapp.address' =>
       "#{float_host(hs_hosts.map{|i| i[:hostname] }.sort.first)}:19888",
    }
  mapred_site_generated_values.merge!(hs_properties)
end

if node[:bcpc][:hadoop][:kerberos][:enable]
   kerberos_data = node[:bcpc][:hadoop][:kerberos][:data]

  if kerberos_data[:historyserver][:princhost] == '_HOST'
    kerberos_host = if node.run_list.expand(node.chef_environment).recipes
                      .include?('bcpc-hadoop::historyserver')
                      float_host(node[:fqdn])
                    else
                      '_HOST'
                    end
  else
    kerberos_host = kerberos_data[:historyserver][:princhost]
  end

  jobhistory_principal =
    kerberos_data[:nodemanager][:principal] + '/' + kerberos_host + '@' +
    node[:bcpc][:hadoop][:kerberos][:realm]

  kerberos_properties =
    {
     'mapreduce.jobhistory.keytab' =>
       node[:bcpc][:hadoop][:kerberos][:keytab][:dir] + '/' +
       kerberos_data[:jobhistory][:keytab],
     
     'mapreduce.jobhistory.principal' =>
       jobhistory_principal,
    }
  mapred_site_generated_values.merge!(kerberos_properties)
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
