# vim: tabstop=2:shiftwidth=2:softtabstop=2

default['bcpc']['hadoop']['phoenix']['phoenixqs']['username'] = 'phoenixqs'
# For UGI to be able to work properly, we need to specify float host 
# not _HOST, especially since we do not provide keytabs for non floats
default['bcpc']['hadoop']['phoenix']['phoenixqs']['principal'] =\
  "HTTP/#{float_host(node['fqdn'])}@#{node[:bcpc][:hadoop][:kerberos][:realm]}"
# we can also specify a bind interface, this is a little wierd
# normally we specify name or IP, here we specify a "physical" interface
# and the name is deduced by doing a reverse on the first IP address
# the configuration key is "phoenix.queryserver.dns.interface"
# Lets leave this one unused for now, and it only affects UGI and does none 
# for HTTP, also would be nice to file a JIRA to fix this
#default['bcpc']['hadoop']['phoenix']['phoenixqs']['interface'] =\
#  node['bcpc']['networks'][node[:bcpc][:management][:subnet]]['floating']['interface']
default['bcpc']['hadoop']['phoenix']['phoenixqs']['keytab'] =\
  "#{node[:bcpc][:hadoop][:kerberos][:keytab][:dir]}/" +
  node[:bcpc][:hadoop][:kerberos][:data][:spnego][:keytab]
default['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] = true
default['bcpc']['hadoop']['phoenix']['phoenixqs']['serialization'] = 'JSON'
