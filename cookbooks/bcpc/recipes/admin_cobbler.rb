#
# Cookbook Name:: bcpc
# Recipe:: cobbler
#
# 
# Generate a fake cobbler credential enough for vagrant to work.
# Only meant for VM clusters
#

root_password = get_config('cobbler-root-password')
root_password = 'vagrant' if root_password.nil?

root_password_salted = root_password.crypt('$6$' + rand(36**8).to_s(36))

chef_vault_secret 'cobbler' do
  data_bag 'os'
  raw_data('root-password' => root_password,
           'root-password-salted' => root_password_salted)
  admins node[:fqdn]
  search '*:*'
  action :create_if_missing
end

