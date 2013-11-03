
package "oozie" do 
	action :upgrade
end

#TODO, this probably has dependencies on external services such as yarn and hive as well
service "oozie" do 
  action [:enable, :start]
  subscribes :restart, "template[/etc/oozie/conf/oozie-site.xml]", :delayed
  subscribes :restart, "template[/etc/oozie/conf/oozie-env.sh]", :delayed
end
  

