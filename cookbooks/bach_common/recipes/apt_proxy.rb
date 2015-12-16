#
# Cookbook Name:: bach_common
# Recipe:: apt_proxy
#

if(node['bach']['http_proxy'] || node['bach']['https_proxy'])
  template '/etc/apt/apt.conf.d/00proxy' do
    user 'root'
    group 'root'
    mode 0444
    source 'apt/00proxy.erb'
    variables({ :http_proxy => node['bach']['http_proxy'],
                :https_proxy => node['bach']['https_proxy'] })
  end
end

