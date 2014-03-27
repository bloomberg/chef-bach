include_recipe 'dpkg_autostart'

dpkg_autostart "jmxtrans" do
  allow false
end

pkg = "jmxtrans_20121016-175251-ab6cfd36e3-1_all.deb"
# split package name on the first underscore to get the package name for dpkg to look-up
package "#{pkg.split('_',2)[0]}" do
  action :install
  version "20121016-175251-ab6cfd36e3-1"
end

template "/var/lib/jmxtrans/hadoop_namenode.json" do
    source "jmxtrans_hadoop_namenode.json.erb"
    owner "root"
    group "root"
    mode 00644
    variables( :servers => get_head_nodes,
               :min_quorum => get_head_nodes.length/2 + 1 )
    notifies :restart, "service[jmxtrans]", :delayed
end

service "jmxtrans" do
  action :nothing
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "template[/var/lib/jmxtrans/hadoop_namenode.json]", :delayed
end
