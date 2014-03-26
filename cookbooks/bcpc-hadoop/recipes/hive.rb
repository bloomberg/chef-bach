
%w{hive-server hive-hbase}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "hive-server" do
  action [:enable, :start]
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
end
