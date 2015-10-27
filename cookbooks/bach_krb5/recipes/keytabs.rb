keytab_dir = node[:bcpc][:hadoop][:kerberos][:keytab][:dir]
realm = node[:bcpc][:hadoop][:kerberos][:realm]

get_all_nodes().each do |h|
  # Create directory for the the host to store keytabs
  directory "#{keytab_dir}/#{float_host(h[:fqdn])}" do
    action :create
    owner "root"
    group "root"
    mode 0755
    recursive true
  end
  
  # Generate all the principals
  node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|
  
    service_principal = va['principal']
    host_fqdn = float_host(h[:fqdn])
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

if node[:bcpc][:hadoop][:kerberos][:additional][:hosts].count > 0
  # Create keytabs for additional hosts
  node[:bcpc][:hadoop][:kerberos][:additional][:hosts].each do |h|
    # Create directory for the the host to store keytabs
    directory "#{keytab_dir}/#{h}" do
      action :create
      owner "root"
      group "root"
      mode 0755
      recursive true
    end

    # Generate all the principals
    node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|

      service_principal = va['principal']
      host_fqdn = h
      keytab_file = "#{h.split(".")[0]}_#{va['principal']}"

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
end

# Create keytabs for regular hosts that are present in chef-server
get_all_nodes().each do |h|
  node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|
    service_principal = va['principal']
    host_fqdn = float_host(h[:fqdn])
    keytab_file = va['keytab']

    # Create the keytab file
    execute "creating-keytab-for-#{ke}" do
      command "kadmin.local -q 'xst -k #{keytab_dir}/#{host_fqdn}/#{keytab_file} -norandkey #{service_principal}/#{host_fqdn}@#{realm} HTTP/#{host_fqdn}@#{realm}'"
      action :run
      not_if {File.exists?("#{keytab_dir}/#{host_fqdn}/#{keytab_file}")}
    end
  end
end

if node[:bcpc][:hadoop][:kerberos][:additional][:hosts].count > 0
  # Generate keytabs for additional hosts
  node[:bcpc][:hadoop][:kerberos][:additional][:hosts].each do |h|
    node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|

      service_principal = va['principal']
      host_fqdn = h
      keytab_file = "#{h.split(".")[0]}_#{va['principal']}"

      # Create the keytab file
      execute "creating-keytab-for-#{ke}" do
        command "kadmin.local -q 'xst -k #{keytab_dir}/#{host_fqdn}/#{keytab_file} -norandkey #{service_principal}/#{host_fqdn}@#{realm} HTTP/#{host_fqdn}@#{realm}'"
        action :run
        not_if {File.exists?("#{keytab_dir}/#{host_fqdn}/#{keytab_file}")}
      end
    end
  end
end

# Upload all the keytabs to data bag/chef vault
include_recipe "bach_krb5::upload_keytabs"
