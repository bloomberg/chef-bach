hdp_version = node[:bcpc][:hadoop][:distribution][:active_release]
 
mapred_site_generated_values = {
  'tez.lib.uris' => '/hdp/apps/#{hdp_version}/tez/tez.tar.gz'
}

template "/etc/hadoop/conf/tez-site.xml" do
  source "generic_site.xml.erb"
  mode 0644
  variables(:options => mapred_site_generated_values)
end
