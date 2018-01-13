# vim: tabstop=2:shiftwidth=2:softtabstop=2

default['bcpc']['hadoop']['phoenix']['phoenixqs']['username'] = 'phoenixqs'
# For UGI to be able to work properly, we need to specify float host 
# not _HOST, especially since we do not provide keytabs for non floats
default['bcpc']['hadoop']['phoenix']['phoenixqs']['principal'] =\
  "HTTP/#{float_host(node['fqdn'])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}" 
default['bcpc']['hadoop']['phoenix']['phoenixqs']['keytab'] =\
  "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/" +
  node[:bcpc][:hadoop][:kerberos][:data][:spnego][:keytab]
default['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] = true
default['bcpc']['hadoop']['phoenix']['phoenixqs']['serialization'] = 'JSON'
