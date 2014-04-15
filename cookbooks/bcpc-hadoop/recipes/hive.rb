# workaround for hcatalog dpkg not creating the hcat user it requires
user "hcat" do 
  username "hcat"
  system true
  shell "/bin/bash"
  home "/usr/lib/hcatalog"
  supports :manage_home => false
end

%w{hive hcatalog}.each do |pkg|
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

template "hive-server2-service" do
  path "/etc/init.d/hive-server2"
  source "hv_hive-server2.erb"
  owner "root"
  group "root"
  mode "0755"
#  notifies :enable, "service[hive-server2]"
#  notifies :start, "service[hive-server2]"
end



bash "hiveserver2" do
  code "nohup /usr/lib/hive/bin/hiveserver2 -hiveconf hive.metastore.uris=\" \" > /var/log/hiveServer2.out 2>/var/log/hive/hiveServer2.log &"
  user "hive"
  action :run
  not_if { true }
end


service "hive-server2" do
#  action [:enable, :start]
  action :nothing
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/etc/hive/conf/hive-site.xml]", :delayed
  subscribes :restart, "template[/etc/hive/conf/hive-log4j.properties]", :delayed
end

