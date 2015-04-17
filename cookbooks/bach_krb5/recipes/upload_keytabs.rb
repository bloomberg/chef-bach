require 'base64'
require 'chef-vault'

# create databag keytabs for keytab files
create_databag('keytabs')

# Upload keytabs to chef-server
get_all_nodes().each do |h|
  node[:bcpc][:hadoop][:kerberos][:data].each do |srvc, srvdat|
    # Set host based on configuration 
    config_host=srvdat['princhost'] == "_HOST" ? float_host(h[:hostname]) : srvdat['princhost'].split('.')[0]
    keytab_host=srvdat['princhost'] == "_HOST" ? float_host(h[:fqdn]) : srvdat['princhost']

    # Delete existing configuration item (if requested)
    chef_vault_secret "#{ config_host }-#{ srvc }" do
      data_bag 'keytabs'
      admins "amdin"
      action :delete
      only_if { node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] }
    end

    # Crete configuration in data bag
    keytab_file = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{keytab_host}/#{srvdat['keytab']}"
    chef_vault_secret "#{ config_host }-#{ srvc }" do
      data_bag 'keytabs'
      raw_data lazy { ({ 'krb5_key' => Base64.encode64(File.open(keytab_file,"rb").read) }) }
      admins "#{h[:hostname]}.#{node[:bcpc][:domain_name]}"
      search '*:*'
      action :create_if_missing
      only_if { File.exists?("#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir] }/#{ keytab_host }/#{ srvdat['keytab'] }") }
    end
  end
end
