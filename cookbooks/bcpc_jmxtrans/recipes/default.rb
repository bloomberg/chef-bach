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

graphite_hosts = get_nodes_for("graphite","bcpc").map{|x| x.bcpc.management.ip}

jmx_services = Array.new

graphite_hosts.each do |host|
  if host == node['bcpc']['management']['ip']
    jmx_services.push("carbon-relay")
    jmx_services.push("carbon-cache")
    break
  end
end

node['jmxtrans']['servers'].each do |server|
  jmx_services.push(server['service'])
end

jmx_services.each do |jmxservice| 
  service "jmxtrans" do
    supports :restart => true, :status => true, :reload => true
    action   :nothing
    subscribes :restart, "service[#{jmxservice}]", :delayed
  end
end
