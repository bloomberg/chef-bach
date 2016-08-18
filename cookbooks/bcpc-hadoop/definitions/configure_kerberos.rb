define :configure_kerberos do
  if node[:bcpc][:hadoop][:kerberos][:enable]
    service_name = params[:service_name]
    keytab_dir = node[:bcpc][:hadoop][:kerberos][:keytab][:dir]
    srvdat = node[:bcpc][:hadoop][:kerberos][:data][service_name]
    srvc=service_name
    keytab_file = srvdat['keytab']
    config_host = srvdat['princhost'] == "_HOST" ?  float_host(node[:hostname]) : srvdat['princhost'].split('.')[0]
    # Delete existing keytab if keytab is being re-created
    file "#{keytab_dir}/#{keytab_file}" do
      action :delete
      only_if {
        File.exists?("#{keytab_dir}/#{keytab_file}") &&
        node[:bcpc][:hadoop][:kerberos][:keytab][:recreate] == true
      }
    end

    # Create the keytab file
    file "#{keytab_dir}/#{keytab_file}" do
      owner "#{srvdat['owner']}"
      group "root"
      mode "#{srvdat['perms']}"
      action :create_if_missing
      content lazy { Base64.decode64(get_config!("#{config_host}-#{srvc}")) }
      only_if { user_exists?("#{srvdat['owner']}")  }
    end

    princ_host = srvdat['princhost'] == "_HOST" ? float_host(node[:fqdn]) : srvdat['princhost']

    execute "kdestroy-for-#{srvdat['owner']}" do
      command "kdestroy"
      user "#{srvdat['owner']}"
      action :run
      only_if { user_exists?("#{srvdat['owner']}") }
    end

    execute "kinit-for-#{srvdat['owner']}" do
      command "kinit -kt #{keytab_dir}/#{keytab_file} #{srvdat['principal']}/#{princ_host}"
      action :run
      user "#{srvdat['owner']}"
      only_if { user_exists?("#{srvdat['owner']}") }
    end
  end
end
