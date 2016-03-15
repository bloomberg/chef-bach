# Set master passwords
create_databag('configs')
bootstrap = get_bootstrap

chef_vault_secret "krb5-master" do
  data_bag 'os'
  raw_data({ 'password' => secure_password })
  admins bootstrap
  search ''
  action :nothing
end.run_action(:create_if_missing)

chef_vault_secret "krb5-admin" do
  data_bag 'os'
  raw_data({ 'password' => secure_password })
  admins bootstrap
  search ''
  action :nothing
end.run_action(:create_if_missing)

# Override password related node attributes
node.override['krb5']['master_password'] = get_config!("password","krb5-master","os")
node.override['krb5']['admin_password'] = get_config!("password","krb5-admin","os")
