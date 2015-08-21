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
  options   ['missingok', 'compress']
  postrotate '/usr/bin/truncate --size=0 /var/log/chef-server/nginx/access.log'
end
