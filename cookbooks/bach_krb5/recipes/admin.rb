include_recipe 'bcpc::admin_base'

# Set master passwords
ruby_block 'set master passwords' do
  block do
    make_config("krb5-master-password", secure_password)
    make_config("krb5-admin-password", secure_password)
  end
end
