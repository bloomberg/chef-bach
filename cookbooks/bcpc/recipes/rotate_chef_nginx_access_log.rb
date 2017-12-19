#
# Cookbook Name:: bcpc
# Recipe:: rotate_chef_nginx_access_log
#
# Prevent chef-server's nginx access.log from filling up
# a partition
#

logrotate_app 'chef-server-nginx-access-log' do
  path '/var/log/chef-server/nginx/access.log'
  frequency 'daily'
  rotate 5
  options %w(missingok notifempty compress delaycompress copytruncate)
  postrotate '/opt/chef-server/embedded/sbin/nginx -s reopen'
end
