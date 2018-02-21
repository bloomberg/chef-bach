#
# Cookbook Name:: ambari
# Recipe:: ambari_views_setup
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# create an instance of Files View
bash 'create instance of Files view' do
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

# # create an instance of Hive View
# bash 'create instance of Hive view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url']}/HIVE/versions/1.0.0/instances/HIVE_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Hive View",
#       "label" : "Hive View",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['ambari']['webhdfs.url']}",
#       "hive.host" : "#{node['ambari']['hive.host']}",
#       "hive.http.path" : "#{node['ambari']['hive.http.path']}",
#       "hive.http.port" : "#{node['ambari']['hive.http.port']}",
#       "hive.metastore.warehouse.dir" : "#{node['ambari']['hive.metastore.warehouse.dir']}",
#       "hive.port" : "#{node['ambari']['hive.port']}",
#       "hive.transport.mode" : "#{node['ambari']['hive.transport.mode']}",
#       "yarn.ats.url" : "#{node['ambari']['yarn.ats.url']}",
#       "yarn.resourcemanager.url" : "#{node['ambari']['yarn.resourcemanager.url']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Hive 1.5 View
# bash 'create instance of Hive 1.5 view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url']}/HIVE/versions/1.5.0/instances/HIVE_NEW_INSTANCE_1_5 \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Hive View 1.5",
#       "label" : "Hive View 1.5",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['ambari']['webhdfs.url']}",
#       "hive.host" : "#{node['ambari']['hive.host']}",
#       "hive.http.path" : "#{node['ambari']['hive.http.path']}",
#       "hive.http.port" : "#{node['ambari']['hive.http.port']}",
#       "hive.metastore.warehouse.dir" : "#{node['ambari']['hive.metastore.warehouse.dir']}",
#       "hive.port" : "#{node['ambari']['hive.port']}",
#       "hive.transport.mode" : "#{node['ambari']['hive.transport.mode']}",
#       "yarn.ats.url" : "#{node['ambari']['yarn.ats.url']}",
#       "yarn.resourcemanager.url" : "#{node['ambari']['yarn.resourcemanager.url']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Tez View
# bash 'create instance of Tez view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url']}/TEZ/versions/0.7.0.2.5.3.0-136/instances/TEZ_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Tez View",
#       "label" : "Tez View",
#       "properties" : {
#       "webhdfs.url" : "#{node['ambari']['webhdfs.url']}",
#       "yarn.ats.url" : "#{node['ambari']['yarn.ats.url']}",
#       "yarn.resourcemanager.url" : "#{node['ambari']['yarn.resourcemanager.url']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Pig View
# bash 'create instance of Pig view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url']}/PIG/versions/1.0.0/instances/PIG_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Pig View",
#       "label" : "Pig View",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['ambari']['fs.defaultFS']}",
#       "webhcat.hostname" : "#{node['ambari']['webhcat.hostname']}",
#       "webhcat.port" : "#{node['ambari']['webhcat.port']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Workflow Manager View
# bash 'create instance of Workflow Manager view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url']}/WORKFLOW_MANAGER/versions/1.0.0/instances/WF_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Workflow Manager View",
#       "label" : "Workflow Manager View",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['ambari']['fs.defaultFS']}",
#       "oozie.service.uri" : "#{node['ambari']['oozie.service.uri']}",
#       "hadoop.security.authentication" : "#{node['ambari']['hadoop.security.authentication']}",
#       "yarn.resourcemanager.address" : "#{node['ambari']['yarn.resourcemanager.address']}"
#       }
#     }
# }'
#     EOH
# end
