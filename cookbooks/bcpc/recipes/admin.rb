include_recipe 'bcpc::admin_base'

# Various other admin accounts usually needed by
# "c-a-r Bootstrap"

# bcpc::keepalived
ruby_block 'keepalived databags' do
  block do
    make_config('keepalived-router-id', "#{(rand * 1000).to_i%254/2*2+1}")
  end
  not_if { get_config('keepalived-router-id') }
end

chef_vault_secret "keepalived" do
  data_bag 'os'
  raw_data lazy {
    { 'password' => secure_password }
  }
  admins Chef::Config.node_name
  search '*:*'
  action :create_if_missing
end

ruby_block 'haproxy databags' do
  block do
    make_config('haproxy-stats-user', 'haproxy')
  end
  not_if {  get_config('haproxy-stats-user') }
end

chef_vault_secret 'haproxy-stats' do
  data_bag 'os'
  raw_data lazy { 
    { 'password' => secure_password }
  }
  admins Chef::Config.node_name
  search '*:*'
  action :create_if_missing
end

ruby_block 'powerdns databags' do
  block do
    make_config('mysql-pdns-user', 'pdns')
  end
  only_if { node['bach']['vm_cluster'] }
  not_if {  get_config('mysql-pdns-user') }
end

chef_vault_secret 'mysql-pdns' do
  data_bag 'os'
  raw_data lazy {
    { 'password' => secure_password }
  }
  admins Chef::Config.node_name
  search '*:*'
  action :create_if_missing
  only_if { node['bach']['vm_cluster'] }
end

