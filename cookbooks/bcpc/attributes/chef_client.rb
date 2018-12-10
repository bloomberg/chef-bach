#
# Cookbook Name:: bcpc
# File:: attributes/chef_client.rb
#
# This file contains configuration for the chef-client cookbook, to
# ensure both bootstrap and client nodes configure chef correctly.
#

#
# The size of the result set on a host bound to a directory service
# will cause chef-client runs to fail to upload the node object.
#
# The solution is to disable the passwd plugin, so users are not
# recorded on the chef server.

# XXX the below keeps breaking Chef12
# knife default['ohai']['disabled_plugins'] = [ 'passwd' ]

# FIXME No longer needed in chef-client 13.2+
default['chef_client']['log_rotation']['postrotate'] = '/etc/init.d/chef-client restart >/dev/null || :'

default['chef_client']['config'].tap do |config|
  config['log_level'] = ':info'
  config['log_location'] = 'STDOUT'

  if node['bcpc']['bootstrap']['proxy']
    config['http_proxy'] = node['bcpc']['bootstrap']['proxy']
    config['https_proxy'] = node['bcpc']['bootstrap']['proxy']
    config['no_proxy'] = node['bcpc']['no_proxy'].join(',')
  end
end
