default['bcpc']['country']      = 'US'
default['bcpc']['state']        = 'NY'
default['bcpc']['location']     = 'New York'
default['bcpc']['organization'] = 'Bloomberg'

# ----------------------------- SSH ------------------------------
default['bcpc']['ssh']['key_size'] = 4096

# ----------------------------- SSL ------------------------------
default['bcpc']['ssl']['key_size'] = 4096
# conf
default['bcpc']['ssl']['conf_file'] = '/tmp/bach_openssl.cnf'
# public key (certificate)
default['bcpc']['ssl']['cert_file_dir'] = '/usr/local/share/ca-certificates/bcpc/'
default['bcpc']['ssl']['cert_file'] = '/usr/local/share/ca-certificates/ssl-bcpc.crt'
default['bcpc']['ssl']['pem_file_dir'] = '/etc/ssl/certs/'
default['bcpc']['ssl']['pem_file'] = '/etc/ssl/certs/ssl-bcpc.pem'
# private key
default['bcpc']['ssl']['key_file_dir'] = '/etc/ssl/private/'
default['bcpc']['ssl']['key_file'] = '/etc/ssl/private/ssl-bcpc.key'
