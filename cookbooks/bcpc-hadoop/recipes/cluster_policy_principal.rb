# FIXME: All these principal generators probably need refactoring.  Have
# shamelylessly copy-pasted for now.

policy_keytab = get_config 'keytab', 'bach_policy_keytab', 'os'
results = get_all_nodes.map!{ |x| x['fqdn'] }.join(",")
nodes = results == "" ? node['fqdn'] : results
bootstrap = get_bootstrap

execute 'bach_policy: create principal' do
  command "kadmin.local -q 'add_principal -randkey bach_policy'" 
  notifies :run, 'ruby_block[bach_policy: create temp file keytab]', :immediate
  not_if { policy_keytab }
end

ruby_block 'bach_policy: create temp file keytab'  do
  block do
    tmpfile = Tempfile.new('bach_policy')
    node.run_state['bach_policy_keytab_file'] = tmpfile.path
    tmpfile.close
    tmpfile.unlink
  end
  action :nothing
  notifies :run, 'execute[bach_policy: dump keytab]', :immediate
end

execute 'bach_policy: dump keytab' do
  command lazy {
    "kadmin.local -q \"ktadd -k #{node.run_state['bach_policy_keytab_file']}" \
    ' -norandkey bach_policy"'
  }
  action :nothing
  notifies :run, 'ruby_block[bach_policy: read in keytab]', :immediate
end

ruby_block 'bach_policy: read in keytab' do
  block do
    node.run_state['bach_policy_base64_keytab'] = 
      Base64.encode64(File.open(
        node.run_state['bach_policy_keytab_file'],'rb').read)
  end
  action :nothing
  notifies :create, 'chef_vault_secret[bach_policy_keytab]', :immediate
end

chef_vault_secret 'bach_policy_keytab' do
  provider ChefVaultCookbook::Provider::ChefVaultSecret
  data_bag 'os'
  raw_data ( lazy {{ 'keytab' => node.run_state['bach_policy_base64_keytab']}})
  search '*:*'
  admins "#{ nodes },#{ bootstrap }"
  action :nothing
  notifies :run, 'ruby_block[bach_policy: delete temp file keytab]', :immediate
end

ruby_block 'bach_policy: delete temp file keytab' do
  block do
    File.unlink(node.run_state['bach_policy_keytab_file'])
  end
  action :nothing
end
