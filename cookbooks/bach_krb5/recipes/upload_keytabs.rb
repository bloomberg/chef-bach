require 'base64'
# Upload keytabs to chef-server
get_all_nodes().each do |h|
  node[:bcpc][:hadoop][:kerberos][:data].each do |srvc, srvdat|
    # Set host based on configuration
    config_host=srvdat['princhost'] == "_HOST" ? float_host(h[:hostname]) : srvdat['princhost'].split('.')[0]
    keytab_host=srvdat['princhost'] == "_HOST" ? float_host(h[:fqdn]) : srvdat['princhost']

    # Delete existing configuration item (if requested)
    config_key = "#{config_host}-#{srvc}"
    delete_config(config_key) if node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true

    # Crete configuration in data bag
    ruby_block "uploading-keytab-for-#{config_key}" do
      block do
        keytab_file = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{keytab_host}/#{srvdat['keytab']}"
        make_config("#{config_key}",Base64.encode64(File.open(keytab_file,"rb").read))
      end
      action :create
      only_if {File.exists?("#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{keytab_host}/#{srvdat['keytab']}") && get_config("#{config_host}-#{srvdat['principal']}").nil?}
    end
  end
end

if node[:bcpc][:hadoop][:kerberos][:additional][:hosts].count > 0
  # Upload keytabs to chef-server for additional hosts
  node[:bcpc][:hadoop][:kerberos][:additional][:hosts].each do |h|
    node[:bcpc][:hadoop][:kerberos][:data].each do |srvc, srvdat|

      # Set host based on configuration
      config_host=srvdat['princhost'] == "_HOST" ? h.split('.')[0] : srvdat['princhost'].split('.')[0]
      keytab_host=srvdat['princhost'] == "_HOST" ? h : srvdat['princhost']
      keytab = "#{h.split(".")[0]}_#{srvdat['principal']}"
    
      # Delete existing configuration item (if requested)
      config_key = "#{config_host}-#{srvc}"
      delete_config(config_key) if node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true

      # Crete configuration in data bag
      ruby_block "uploading-keytab-for-#{config_key}" do
        block do
          keytab_file = "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{keytab_host}/#{keytab}"
          make_config("#{config_key}",Base64.encode64(File.open(keytab_file,"rb").read))
        end
        action :create
        only_if {File.exists?("#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/#{keytab_host}/#{keytab}") && get_config("#{config_host}-#{srvdat['principal']}").nil?}
      end
    end
  end
end
