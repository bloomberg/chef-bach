
template "/etc/init.d/hadoop-yarn-timelineserver" do
  source "hdp_hadoop-yarn-timelineserver-initd.erb"
  mode 0655
end

service "hadoop-yarn-timelineserver" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hadoop/conf/hadoop-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/yarn-site.xml]", :delayed
end


