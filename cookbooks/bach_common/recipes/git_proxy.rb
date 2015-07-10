#
# Cookbook Name:: bach_common
# Recipe:: git_proxy
#

package 'git' do
  action :install
end

if(node['bach']['http_proxy'])
  execute 'git_http_proxy' do
    command "git config --system http.proxy #{ node['bach']['http_proxy'] }"
  end
end
