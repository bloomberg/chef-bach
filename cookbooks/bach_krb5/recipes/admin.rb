include_recipe 'bcpc::admin_base'

# Set master passwords
ruby_block 'set master passwords' do
  block do
    make_config("krb5-master-password", secure_password)
    make_config("krb5-admin-password", secure_password)
  end
end



if node['bach']['krb5']['generate_keytabs']

  node.default['bcpc']['hadoop']['kerberos']['keytab']['dir'] = '/home/vagrant/keytabs'

  kadmind = service 'kadmind' do
    service_name 'krb5-admin-server'
    action :nothing
  end.provider_for_action :start
  delete_resource :service, 'kadmind'
  node.run_state[:kadmind_service] = kadmind.load_current_resource

  if node.run_state[:kadmind_service].running
    include_recipe 'bach_krb5::keytabs'
  else
    log 'kdc not ready' do
      message 'KDC not yet setup, skipping keytab generation.  '\
        'Rerun after converging the bootstrap machine'
      level :warn
    end
  end
else
  include_recipe 'bach_krb5::default'
  include_recipe 'bach_krb5::upload_keytabs'
end

