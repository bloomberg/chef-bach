#
# Cookbook Name:: bach_common
# Recipe:: gem_proxy
#

[ '/opt/chef/embedded/ssl', '/opt/chef/embedded/etc' ].each do |path|
  directory path do
    recursive true
    mode 0555
  end
end

link '/opt/chef/embedded/ssl/cert.pem' do
  to '/etc/ssl/certs/ca-certificates.crt'
end

gemrc = "gem: --http-proxy #{node['bach']['http_proxy']}\n"

file '/opt/chef/embedded/etc/gemrc' do
  mode 0444
  content gemrc
end

file '/etc/gemrc' do
  mode 0444
  content gemrc
end
