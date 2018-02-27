# vim: tabstop=2:shiftwidth=2:softtabstop=2

include_recipe 'bcpc-hadoop::phoenixqs_kerberos'

qs_runas = node['bcpc']['hadoop']['phoenix']['phoenixqs']['username']

user qs_runas do
  comment 'Runs phoenix queryserver'
  only_if { node['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] }
  # apperently these do not happen in order
  # and group 'hadoop' was being run furst
  notifies :modify, "group[add #{qs_runas} to hadoop]", :immediate
end

group "add #{qs_runas} to hadoop" do
  group_name 'hadoop'
  members [ qs_runas ]
  append true
  action :nothing
  only_if { node['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] }
end

configure_kerberos 'phoenixqs_keytab' do
  service_name 'phoenixqs'
end


template '/etc/init.d/pqs' do
  source 'etc_initd_pqs.erb'
  variables(qs_runas: qs_runas) 
  mode 0o755
  notifies :restart, 'service[pqs]', :delayed
end

service 'pqs' do
  action [:enable, :start]
  supports status: true, restart: true 
  subscribes :restart, 'template[/etc/hbase/conf/hbase-site.xml]', :delayed
  # we need to know wheh proxyuser chnages
  #https://github.com/apache/phoenix/blob/27d6582827b9306e66d3bfd430c6186ac165fb08/phoenix-queryserver/src/main/java/org/apache/phoenix/queryserver/server/QueryServer.java#L242-L243
  subscribes :restart, 'template[/etc/hadoop/conf/core-site.xml]', :delayed
end
