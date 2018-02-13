#
# Cookbook Name:: bach_ambari
# Recipe:: ambari_views_setup
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# create an instance of Files View
bash 'create instance of Files view' do
  code <<-EOH
    curl --user #{node['bach_ambari']['admin']['user']}:#{node['bach_ambari']['admin']['password']} -i -H 'X-Requested-By: ambari' -X POST #{node['bach_ambari']['ambari_views_url']}/FILES/versions/1.0.0/instances/FILES_NEW_INSTANCE \
--data '{
  "ViewInstanceInfo" : {
      "description" : "Files API",
      "label" : "Files View",
      "properties" : {
      "webhdfs.client.failover.proxy.provider" : "#{node['bach_ambari']['webhdfs.client.failover.proxy.provider']}",
      "webhdfs.ha.namenode.http-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn1']}",
      "webhdfs.ha.namenode.http-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn2']}",
      "webhdfs.ha.namenode.https-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn1']}",
      "webhdfs.ha.namenode.https-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn2']}",
      "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
      "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
      "webhdfs.ha.namenodes.list" : "#{node['bach_ambari']['webhdfs.ha.namenodes.list']}",
      "webhdfs.nameservices" : "#{node['bach_ambari']['webhdfs.nameservices']}",
      "webhdfs.url" : "#{node['bach_ambari']['webhdfs.url']}",
      "webhdfs.auth" : "#{node['bach_ambari']['webhdfs.auth']}"
      }
    }
}'
    EOH
end

# # create an instance of Hive View
# bash 'create instance of Hive view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['bach_ambari']['ambari_views_url']}/HIVE/versions/1.0.0/instances/HIVE_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Hive View",
#       "label" : "Hive View",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['bach_ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['bach_ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['bach_ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['bach_ambari']['webhdfs.url']}",
#       "hive.host" : "#{node['bach_ambari']['hive.host']}",
#       "hive.http.path" : "#{node['bach_ambari']['hive.http.path']}",
#       "hive.http.port" : "#{node['bach_ambari']['hive.http.port']}",
#       "hive.metastore.warehouse.dir" : "#{node['bach_ambari']['hive.metastore.warehouse.dir']}",
#       "hive.port" : "#{node['bach_ambari']['hive.port']}",
#       "hive.transport.mode" : "#{node['bach_ambari']['hive.transport.mode']}",
#       "yarn.ats.url" : "#{node['bach_ambari']['yarn.ats.url']}",
#       "yarn.resourcemanager.url" : "#{node['bach_ambari']['yarn.resourcemanager.url']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Hive 1.5 View
# bash 'create instance of Hive 1.5 view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['bach_ambari']['ambari_views_url']}/HIVE/versions/1.5.0/instances/HIVE_NEW_INSTANCE_1_5 \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Hive View 1.5",
#       "label" : "Hive View 1.5",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['bach_ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['bach_ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['bach_ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['bach_ambari']['webhdfs.url']}",
#       "hive.host" : "#{node['bach_ambari']['hive.host']}",
#       "hive.http.path" : "#{node['bach_ambari']['hive.http.path']}",
#       "hive.http.port" : "#{node['bach_ambari']['hive.http.port']}",
#       "hive.metastore.warehouse.dir" : "#{node['bach_ambari']['hive.metastore.warehouse.dir']}",
#       "hive.port" : "#{node['bach_ambari']['hive.port']}",
#       "hive.transport.mode" : "#{node['bach_ambari']['hive.transport.mode']}",
#       "yarn.ats.url" : "#{node['bach_ambari']['yarn.ats.url']}",
#       "yarn.resourcemanager.url" : "#{node['bach_ambari']['yarn.resourcemanager.url']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Tez View
# bash 'create instance of Tez view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['bach_ambari']['ambari_views_url']}/TEZ/versions/0.7.0.2.5.3.0-136/instances/TEZ_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Tez View",
#       "label" : "Tez View",
#       "properties" : {
#       "webhdfs.url" : "#{node['bach_ambari']['webhdfs.url']}",
#       "yarn.ats.url" : "#{node['bach_ambari']['yarn.ats.url']}",
#       "yarn.resourcemanager.url" : "#{node['bach_ambari']['yarn.resourcemanager.url']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Pig View
# bash 'create instance of Pig view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['bach_ambari']['ambari_views_url']}/PIG/versions/1.0.0/instances/PIG_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Pig View",
#       "label" : "Pig View",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['bach_ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['bach_ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['bach_ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['bach_ambari']['fs.defaultFS']}",
#       "webhcat.hostname" : "#{node['bach_ambari']['webhcat.hostname']}",
#       "webhcat.port" : "#{node['bach_ambari']['webhcat.port']}"
#       }
#     }
# }'
#     EOH
# end
#
# # create an instance of Workflow Manager View
# bash 'create instance of Workflow Manager view' do
#   code <<-EOH
# curl --user admin:admin -i -H 'X-Requested-By: ambari' -X POST #{node['bach_ambari']['ambari_views_url']}/WORKFLOW_MANAGER/versions/1.0.0/instances/WF_NEW_INSTANCE \
# --data '{
#   "ViewInstanceInfo" : {
#       "description" : "Workflow Manager View",
#       "label" : "Workflow Manager View",
#       "properties" : {
#       "webhdfs.client.failover.proxy.provider" : "#{node['bach_ambari']['webhdfs.client.failover.proxy.provider']}",
#       "webhdfs.ha.namenode.http-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn1']}",
#       "webhdfs.ha.namenode.http-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.http-address.nn2']}",
#       "webhdfs.ha.namenode.https-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn1']}",
#       "webhdfs.ha.namenode.https-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.https-address.nn2']}",
#       "webhdfs.ha.namenode.rpc-address.nn1" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn1']}",
#       "webhdfs.ha.namenode.rpc-address.nn2" : "#{node['bach_ambari']['webhdfs.ha.namenode.rpc-address.nn2']}",
#       "webhdfs.ha.namenodes.list" : "#{node['bach_ambari']['webhdfs.ha.namenodes.list']}",
#       "webhdfs.nameservices" : "#{node['bach_ambari']['webhdfs.nameservices']}",
#       "webhdfs.url" : "#{node['bach_ambari']['fs.defaultFS']}",
#       "oozie.service.uri" : "#{node['bach_ambari']['oozie.service.uri']}",
#       "hadoop.security.authentication" : "#{node['bach_ambari']['hadoop.security.authentication']}",
#       "yarn.resourcemanager.address" : "#{node['bach_ambari']['yarn.resourcemanager.address']}"
#       }
#     }
# }'
#     EOH
# end
