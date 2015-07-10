#
# Cookbook Name:: bach_common
# Recipe:: proxy
#
# As of chef-provisioning 1.2.0 and chef 12.3.0, providing a proxy via
# the convergence_options hash causes an "undefined method `[]' for
# nil:NilClass".  
#
# As a workaround, we smuggle the chef proxy configuration in the environment.
#
['http_proxy', 'https_proxy'].each do |proxy_key|
  if(node['bach'][proxy_key])
     Chef::Config[proxy_key] = node['bach'][proxy_key]
     Chef::Config[:no_proxy] ||= '127.0.0.1,localhost'
     ENV[proxy_key] = node['bach'][proxy_key]
     ENV['no_proxy'] ||= '127.0.0.1,localhost'
  end
end

#
# The central CA bundle needs to be updated, in case proxy certificates
# were copied from the build host into /usr/local/share/ca-certificates.
#
execute 'update-ca-certificates'

log "ENV['SSL_CERT_FILE']: #{ENV['SSL_CERT_FILE']}"
log "node['bach']['http_proxy']: #{node['bach']['http_proxy']}"
log "node['bach']['https_proxy']: #{node['bach']['https_proxy']}"
log "ENV['http_proxy]: #{ENV['http_proxy']}"
log "ENV['https_proxy']: #{ENV['https_proxy']}"
log "Chef::Config.http_proxy: #{Chef::Config.http_proxy}"
log "Chef::Config.https_proxy: #{Chef::Config.https_proxy}"

include_recipe 'bach_common::apt_proxy'
include_recipe 'bach_common::gem_proxy'
include_recipe 'bach_common::git_proxy'

