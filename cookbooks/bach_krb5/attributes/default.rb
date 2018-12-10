# Change default values
node.override[:krb5][:krb5_conf][:libdefaults][:default_realm] = node[:bcpc][:domain_name].upcase
node.override[:krb5][:krb5_conf][:libdefaults][:dns_lookup_kdc] = false
node.override[:krb5][:krb5_conf][:libdefaults][:rdns] = false
node.override[:krb5][:krb5_conf][:libdefaults][:ignore_acceptor_hostname] = true
node.override[:krb5][:krb5_conf][:realms][:default_realm_admin_server] = "#{node[:bcpc][:bootstrap][:hostname]}.#{node[:bcpc][:domain_name]}" 
node.override[:krb5][:lookup_kdc] = false
node.override[:krb5][:krb5_conf][:realms][:default_realm_kdcs] = [ "#{node[:bcpc][:bootstrap][:hostname]}.#{node[:bcpc][:domain_name]}" ]
node.override[:krb5][:admin_principal] = "root/admin"
node.override[:krb5][:krb5_conf][:libdefaults][:proxiable] = true
node.override[:krb5][:krb5_conf][:libdefaults][:renew_lifetime] = "7d"
node.override[:krb5][:client][:authconfig] = 'pam-auth-update --force --package krb5'
default_realm = node[:bcpc][:domain_name].upcase
node.override[:krb5][:kdc_conf][:realms][default_realm][:supported_enctypes] = "arcfour-hmac:normal des3-hmac-sha1:normal des-cbc-crc:normal des:normal des:v4 des:norealm des:onlyrealm des:afs3"
node.override[:krb5][:kdc_conf][:realms][default_realm][:default_principal_flags] = "+renewable"
node.override[:krb5][:kdc_conf][:realms][default_realm][:max_renewable_life] = "7d"

default['bach']['krb5']['generate_keytabs'] = false
