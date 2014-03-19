
%w{hive hive-hbase}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

template "hive-config" do
  path "/usr/lib/hive/bin/hive-config.sh"
  source "hv_hive-config.sh.erb"
  owner "root"
  group "root"
  mode "0755"
end


bash "hiveserver2" do
  code "nohup /usr/lib/hive/bin/hiveserver2 -hiveconf hive.metastore.uris=\" \" > /var/log/hiveServer2.out 2>/var/log/hive/hiveServer2.log &"
  user "hive"
  action :run
  not_if { true }
end


service "hive-server2" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
end
