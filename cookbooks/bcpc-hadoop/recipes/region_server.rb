

package "hbase-regionserver" do
	action :upgrade
end

service "hbase-regionserver" do
	action [:enable, :restart]
end

%w{hadoop-metrics.properties
   hbase-env.sh
   hbase-policy.xml
   hbase-site.xml
   log4j.properties
   regionservers}.each do |t|
  template "/etc/hbase/conf/#{t}" do
    source "hb_#{t}.erb"
    variables(:hh_hosts => get_hadoop_heads, :quorum_hosts => get_quorum_hosts)
  end
end

