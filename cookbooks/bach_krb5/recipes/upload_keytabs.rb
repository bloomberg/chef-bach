require 'base64'

# create databag keytabs for keytab files
create_databag('keytabs')

# Upload keytabs to chef-server
get_all_nodes().each do |h|
  node[:bcpc][:hadoop][:kerberos][:data].each do |srvc, srvdat|
    # Set host based on configuration
    config_host=srvdat['princhost'] == "_HOST" ? float_host(h[:hostname]) : srvdat['princhost'].split('.')[0]
    keytab_host=srvdat['princhost'] == "_HOST" ? float_host(h[:fqdn]) : srvdat['princhost']

    # Delete existing configuration item (if requested)
    config_key = "#{config_host}-#{srvc}"

# Delete existing configuration item (if requested)
    chef_vault_secret "#{ config_key }" do
      data_bag 'keytabs'
      admins ""
      action :delete
      only_if { node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] }
    end

    # Crete configuration in data bag
    keytab_file = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{keytab_host}/#{srvdat['keytab']}"
    chef_vault_secret "#{ config_key }" do
      data_bag 'keytabs'
      raw_data lazy { ({ 'krb5_key' => Base64.encode64(File.open(keytab_file,"rb").read)) }
      admins "#{ h[:fqdn] }"
      search ''
      action :create_if_missing
      only_if { File.exists?("#{node[:bcpc][:hadoop][:keytab][:dir] }/#{ keytab_host }/#{ srvdat['keytab'] }") }
    end
  end
end
