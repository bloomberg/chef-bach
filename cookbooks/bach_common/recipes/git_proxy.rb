#
# Cookbook Name:: bach_common
# Recipe:: git_proxy
#

include_recipe 'bach_common::apt_proxy'
include_recipe 'apt'

package 'git' do
  action :install
end

if(node['bach']['http_proxy'])
  execute 'git_http_proxy' do
    command "git config --system http.proxy #{ node['bach']['http_proxy'] }"
  end
end
