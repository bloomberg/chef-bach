require 'cluster_def'

keytab_dir = node[:bcpc][:hadoop][:kerberos][:keytab][:dir]
realm = node[:bcpc][:hadoop][:kerberos][:realm]
viphost = node[:bcpc][:management][:viphost]
host_list = BACH::ClusterDef.new.fetch_cluster_def()
  .map { |hst| hst[:fqdn] }. + [viphost]

host_list.each do |h|
  include_recipe 'bach_krb5::keytab_directory'

  # Generate all the principals
  node[:bcpc][:hadoop][:kerberos][:data].each do |_ke, va|
    service_principal = va['principal']
    host_fqdn = float_host(h)
    keytab_file = va['keytab']

    # Delete the existing kerberos principal if principal is being recreated
    krb5_principal "#{service_principal}/#{host_fqdn}@#{realm}" do
      action :delete
      only_if do 
        principal_exists?("#{service_principal}/#{host_fqdn}@#{realm}") &&
          node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true
      end 
    end

    # Delete the existing Keytab file if principal is being recreated
    file "#{keytab_dir}/#{host_fqdn}/#{keytab_file}" do
      action :delete
      only_if do 
        File.exist?("#{keytab_dir}/#{host_fqdn}/#{keytab_file}") &&
          node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true
      end
    end

    # Create the principal
    krb5_principal "#{service_principal}/#{host_fqdn}@#{realm}" do
      action :create
      randkey true
      not_if { principal_exists?("#{service_principal}/#{host_fqdn}@#{realm}") }
    end
  end
end

host_list.each do |h|
  host_fqdn = float_host(h)
  # Create a subdirectory for each host.
  directory File.join(keytab_dir, host_fqdn) do
    action :create
    user 'root'
    group 'root'
    mode 0o0700
  end

  node[:bcpc][:hadoop][:kerberos][:data].each do |ke, va|
    service_principal = va['principal']

    keytab_file = va['keytab']
    keytab_path = ::File.join(keytab_dir, host_fqdn, keytab_file)
    regular_principal = "#{service_principal}/#{host_fqdn}@#{realm}"
    vip_principal = "#{service_principal}/#{float_host(viphost)}@#{realm}"

    # Variable to hold all principals for a single keytab
    keytab_principals = "#{regular_principal} #{vip_principal}"

    # Create the keytab file
    execute "creating-keytab-for-#{ke}" do
      command "kadmin.local -q 'xst -k #{keytab_path} " \
        "-norandkey #{keytab_principals}'"
      action :run
      not_if do
        # Don't run if all principals are found in an existing keytab file.
        require 'mixlib/shellout'
        [regular_principal, vip_principal].map do |princ|
          cc = Mixlib::ShellOut.new("klist -k #{keytab_path} | grep #{princ}")
          cc.run_command
          cc.status.success?
        end.all?
      end
    end

    # Verify the keytab file, because kadmin.local does not return errors.
    [regular_principal, vip_principal].each do |princ|
      execute "verifying-#{princ}-keytab" do
        command "klist -k #{keytab_path} | grep #{princ}"
      end
    end
  end
end

# Upload all the keytabs to data bag/chef vault
include_recipe 'bach_krb5::upload_keytabs'
