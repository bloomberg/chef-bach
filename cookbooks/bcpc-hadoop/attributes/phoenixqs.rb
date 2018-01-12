default['bcpc']['hadoop']['phoenix']['phoenixqs']['username'] = 'phoenixqs'
# For UGI to be able to work properly, we need to specify float host 
# not _HOST, especially since we do not provide keytabs for non floats
default['bcpc']['hadoop']['phoenix']['phoenixqs']['principal'] =\
  "HTTP/#{float_host(node['fqdn'])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}" 
default['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] = true
default['bcpc']['hadoop']['phoenix']['phoenixqs']['serialization'] = 'JSON'
