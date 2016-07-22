keytab_dir = node[:bcpc][:hadoop][:kerberos][:keytab][:dir]
realm = node[:bcpc][:hadoop][:kerberos][:realm]
viphost = float_host(node[:bcpc][:management][:viphost])

directory "#{keytab_dir}/#{viphost}" do
  action :create
  owner "root"
  group "root"
  mode 0755
  recursive true
end

get_cluster_nodes().each do |h|
  # Create directory for the the host to store keytabs
  directory "#{keytab_dir}/#{float_host(h)}" do
    action :create
    owner "root"
    group "root"
    mode 0755
    recursive true
  end

  # Generate all the principals
  node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|
  
    service_principal = va['principal']
    host_fqdn = float_host(h)
    keytab_file = va['keytab']
  
    # Delete the existing kerberos principal if principal is being recreated
    krb5_principal "#{service_principal}/#{host_fqdn}@#{realm}" do
      action :delete
      only_if { principal_exists?("#{service_principal}/#{host_fqdn}@#{realm}") && 
                node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true
              }
    end
    
    # Delete the existing Keytab file if principal is being recreated
    file "#{keytab_dir}/#{host_fqdn}/#{keytab_file}" do
      action :delete
      only_if { File.exists?("#{keytab_dir}/#{host_fqdn}/#{keytab_file}") && 
                node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true
              }
    end
    
    # Create the principal
    krb5_principal "#{service_principal}/#{host_fqdn}@#{realm}" do
      action :create
      randkey true
      not_if { principal_exists?("#{service_principal}/#{host_fqdn}@#{realm}") }
    end
  end
end

get_cluster_nodes().each do |h|
  node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|
    service_principal = va['principal']
    host_fqdn = float_host(h)
    keytab_file = "#{keytab_dir}/#{host_fqdn}/#{va['keytab']}"

    # Service principals that will be added to a single keytab
    ktsvprnc = "#{service_principal}/#{host_fqdn}@#{realm}"
    kthtprnc = "HTTP/#{host_fqdn}@#{realm} HTTP/#{viphost}@#{realm}"
    ktvpprnc = "#{service_principal}/#{viphost}@#{realm}" 

    # Variable to hold all principals for a single keytab
    keytab_princs = "#{ktsvprnc} #{kthtprnc} #{ktvpprnc}"
    
    # Create the keytab file
    execute "creating-keytab-for-#{ke}" do
      command "kadmin.local -q 'xst -k #{keytab_file} -norandkey #{keytab_princs}'"
      action :run
      not_if {File.exists?(keytab_file)}
    end
  end
end

# Upload all the keytabs to data bag/chef vault
include_recipe "bach_krb5::upload_keytabs"
