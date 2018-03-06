def isViewInstalled(viewUrl, headers)
  Chef::Log.info("View URL:"+viewUrl)
  res = Chef::HTTP.new("#{node['ambari']['ambari_views_url']}").get(viewUrl, headers)
  return true
rescue Net::HTTPServerException
    Chef::Log.info("View seems not created")
    return false
end
