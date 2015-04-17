# create databag configs if not created
create_databag('configs')

require 'chef-vault'
# Set master and admin passwords when it is not existed
chef_vault_secret "krb5-master" do
  data_bag 'configs'
  raw_data({ 'password' => secure_password })
  admins "bcpc-bootstrap.#{node['bcpc']['domain_name']}"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)

chef_vault_secret "krb5-admin" do
  data_bag 'configs'
  raw_data({ 'password' => secure_password })
  admins "bcpc-bootstrap.#{node['bcpc']['domain_name']}"
  search '*:*'
  action :nothing
end.run_action(:create_if_missing)


# Override password related node attributes
master = ChefVault::Item.load("configs", "krb5-master")
node.override['krb5']['master_password'] = master['password']
admin = ChefVault::Item.load("configs", "krb5-admin")
node.override['krb5']['admin_password'] = admin['password']

