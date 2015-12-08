def principal_exists?(pname) 
  require 'rkerberos'
  kadm5_connected = false
  princ_found = false

  begin
    kadm5 = Kerberos::Kadm5.new(:principal => "#{node[:krb5][:admin_principal]}", :password => "#{get_bach_krb5_config!("krb5-admin-password")}")
    kadm5_connected = true
  rescue Kerberos::Kadm5::Exception
    raise "Can't connect to KDC to verify if principal #{pname} exists."
  end

  if kadm5_connected && !kadm5.find_principal(pname).nil?
    princ_found = true
  end

  return princ_found
end
