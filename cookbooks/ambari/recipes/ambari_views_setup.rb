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
node['ambari']['ambari_views_props'].each do |key, val|
  Chef::Log.info('settting up view '+key)
  http_request "#{key}" do
    url "#{File.join(node['ambari']['ambari_views_url'], val['url'])}"
    action :post
    message (val['data'].to_json)
    headers (req_headers)
   not_if { isViewInstalled("#{val['url']}", req_headers)}
  end
end
