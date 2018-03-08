#
# Cookbook Name:: ambari
# Recipe:: ambari_views_setup
#

http_request 'Polling Ambari WebUi' do
  url "#{node['ambari']['ambari_server_base_url']}"
  retries 24
  retry_delay 5
end

# Prepare Headers for Ambari views REST calls
req_headers = {'AUTHORIZATION' => "Basic #{Base64.encode64("#{node['ambari']['admin']['user']}:#{node['ambari']['admin']['password']}")}}",
  'Content-Type' => 'application/data',
  'X-Requested-By' => 'ambari'
  }

# Ambari views installation
bash 'create_files_view' do
  code <<-EOH
  curl --user #{node['ambari']['admin']['user']}:#{node['ambari']['admin']['password']} -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url'] }/#{node['ambari']['files_path']} \
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
  not_if { isViewInstalled("#{node['ambari']['files_path']}", req_headers)}
end


bash 'create_Hive20_view' do
  code <<-EOH
  curl --user #{node['ambari']['admin']['user']}:#{node['ambari']['admin']['password']} -i -H 'X-Requested-By: ambari' -X POST #{node['ambari']['ambari_views_url'] }/#{node['ambari']['hive20_view_path']} \
  --data '{
    "ViewInstanceInfo" : {
        "description" : "Hive 2.0 View",
        "label" : "Hive 2.0 View",
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
        "webhdfs.auth" : "#{node['ambari']['webhdfs.auth']}",
        "hive.jdbc.url" : "#{node['ambari']['hive.jdbc.url']}",
        "hive.session.params" : "#{node['ambari']['hive20_proxy_user']}",
        "yarn.ats.url" : "#{node['ambari']['yarn.ats.url']}",
        "yarn.resourcemanager.url" : "#{node['ambari']['yarn.resourcemanager.url']}"
        }
      }
  }'
  EOH
  not_if { isViewInstalled("#{node['ambari']['hive20_view_path']}", req_headers)}
end

# node['ambari']['ambari_views_props'].each do |key, val|
#   Chef::Log.info('settting up view '+key)
#   http_request "#{key}" do
#     url "#{File.join(node['ambari']['ambari_views_url'], val['url'])}"
#     action :post
#     message (val['data'].to_json)
#     headers (req_headers)
#    not_if { isViewInstalled("#{val['url']}", req_headers)}
#   end
# end
