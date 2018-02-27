#
# Cookbook Name:: ambari
# Recipe:: ambari_views_setup
#
# Copyright (c) 2016 The Authors, All Rights Reserved.


http_request 'Polling Ambari WebUi' do
  url "#{node['ambari']['ambari_server_base_url']}"
  retries 24
  retry_delay 5
  # notifies :run, 'bash[create_instance_of_Files_view]', :immediately
end

# create an instance of Files View
bash 'create_instance_of_Files_view' do
  # action :nothing
  code <<-EOH
    curl --user #{node['ambari']['admin']['user']}:#{node['ambari']['admin']['password']} -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url']}/FILES/versions/1.0.0/instances/FILES_NEW_INSTANCE \
--data '{
  "ViewInstanceInfo" : {
      "description" : "Files API",
      "label" : "Files View",
      "properties" : {
      "webhdfs.client.failover.proxy.provider" : "#{node['ambari']['webhdfs.client.failover.proxy.provider']}",
      "webhdfs.ha.namenode.http-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
      "webhdfs.ha.namenode.http-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
      "webhdfs.ha.namenode.https-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
      "webhdfs.ha.namenode.https-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
      "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
      "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
      "webhdfs.ha.namenodes.list" : "#{node['ambari']['webhdfs.ha.namenodes.list']}",
      "webhdfs.nameservices" : "#{node['ambari']['webhdfs.nameservices']}",
      "webhdfs.url" : "#{node['ambari']['webhdfs.url']}",
      "webhdfs.auth" : "#{node['ambari']['webhdfs.auth']}"
      }
    }
}'
    EOH
end
