endpoint = node[:hannibal][:service_endpoint]
timeout = node[:hannibal][:service_timeout]

service "hannibal" do
   supports :status => true, :restart => true 
   action [:enable, :start]
   subscribes :restart, "template[application_conf]", :delayed
   subscribes :restart, "template[hannibal_hbase_site]", :delayed
   notifies :run, "ruby_block[wait_for_hannibal]", :delayed 
end

ruby_block "wait_for_hannibal" do
   block do
      wait_until_ready(endpoint, timeout)
   end
   action :nothing
end
