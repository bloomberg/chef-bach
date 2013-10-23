
services = %w{hbase-master hbase-rest hbase-regionserver}

services.each do |p|
  package p do
    action :upgrade
  end
end

services.each do |p|
  service p do
    action :enable
    subscribes :restart, "template[/etc/hbase/conf/hbase-site.xml]", :delayed
    subscribes :restart, "template[/etc/hbase/conf/hbase-policy.xml]", :delayed
  end
end

