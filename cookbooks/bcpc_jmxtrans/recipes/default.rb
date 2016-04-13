#
# Cookbook Name:: bcpc_jmxtrans
# Recipe:: default
#
# Copyright 2014, Bloomberg L.P
#
# All rights reserved 
#

#
# Logic to include the node ip so that the JMXTrans JSON file can be genereated correctly
#
vservers = node['jmxtrans']['servers'].dup

vservers.each do |vserver|
  vserver['name']=node['bcpc']['management']['ip']
  vserver['alias']=vserver['type']+"."+node[:hostname]
  vserver['port']=node["bcpc"]["hadoop"][vserver['type']]["jmx"]["port"]
end

node.override['jmxtrans']['servers']=vservers

#
# Logic to populate the graphite parameters if they are not set
#

if node['jmxtrans']['graphite']['host'].nil? || node['jmxtrans']['graphite']['host'] == 'graphite'
   node.default['jmxtrans']['graphite']['host'] = node['bcpc']['management']['vip']
end

if node.default['jmxtrans']['graphite']['port'] != node['bcpc']['graphite']['relay_port']
   node.default['jmxtrans']['graphite']['port'] = node['bcpc']['graphite']['relay_port']
end
#
# Logic to set the URL from where the jmxtrans software need to be downloaded
#
sw_download_url = get_binary_server_url
node.default['jmxtrans']['url'] = "#{sw_download_url}"+"#{node['jmxtrans']['sw']}"

include_recipe 'jmxtrans'
#
# Get an array of hosts which are garphite heads
#
graphite_hosts = get_nodes_for("graphite","bcpc").map{|x| x.bcpc.management.ip}
#
# Array to store the list of services on which jxmtrans dependent on i.e. collects data from
# If any of the services gets restarted jmxtrans process need to be restarted
#
jmx_services = Array.new
jmx_service_cmds = Hash.new
#
# If the current host is a graphite head add the carbon processes to the list of services array
#
graphite_hosts.each do |host|
  if host == node['bcpc']['management']['ip']
    jmx_services.push("carbon-relay")
    jmx_services.push("carbon-cache")
    jmx_service_cmds["carbon-relay"] = "carbon-relay.py"
    jmx_service_cmds["carbon-cache"] = "carbon-cache.py"
    break
  end
end

ruby_block 'Check GC_OPTS exists in jmxtrans.sh' do
  block do
    raise "jmxtrans.sh does not have GC_OPTS"
  end
  not_if "grep GC_OPTS= #{node['jmxtrans']['home']}/jmxtrans.sh"
end

replace_or_add "replace GC_OPTS with other stuff" do
  path "/opt/jmxtrans/jmxtrans.sh"
  pattern "GC_OPTS=.*"
  line 'GC_OPTS=${GC_OPTS:-"-Xms${HEAP_SIZE}M -Xmx${HEAP_SIZE}M -XX:PermSize=${PERM_SIZE}m -XX:MaxPermSize=${MAX_PERM_SIZE}m"}'
end

#
# Add services of processes on this node from which jmx data are collected by jmxtrans 
#
node['jmxtrans']['servers'].each do |server|
  jmx_services.push(server['service'])
  jmx_service_cmds[server['service']] = server['service_cmd']
end

#
# Ruby block to restart jmxtrans if any of the dependent process is restarted
#
service "restart jmxtrans on dependent service" do
  service_name "jmxtrans"
  supports :restart => true, :status => true, :reload => true
  action   :restart
  #
  # Using the services array generate chef service resources to restart when the monitored services are restarted 
  #
  jmx_services.each do |jmx_dep_service| 
    subscribes :restart, "service[#{jmx_dep_service}]", :delayed
  end
  # Run if we see a service was restarted (either manually or from a service restart subscribed above)
  only_if { process_require_restart?("jmxtrans","jmxtrans-all.jar",jmx_service_cmds) }
end
