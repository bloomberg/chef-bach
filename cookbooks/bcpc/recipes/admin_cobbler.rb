#
# Cookbook Name:: bcpc
# Recipe:: cobbler
#
# 
# Generate a fake cobbler credential enough for vagrant to work.
# Only meant for VM clusters
#


if node['bach']['vm_cluster']
  include_recipe 'bcpc::admin_base'

  root_password = 'vagrant'
  root_password_salted = root_password.crypt('$6$' + rand(36**8).to_s(36))

  chef_vault_secret 'cobbler' do
    data_bag 'os'
    raw_data('root-password' => root_password,
             'root-password-salted' => root_password_salted)
    admins Chef::Config.node_name
    search '*:*'
    action :create_if_missing
  end

end
