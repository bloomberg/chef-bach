default['bcpc']['hadoop']['phoenix']['phoenixqs']['username'] = 'phoenixqs'
default['bcpc']['hadoop']['phoenix']['phoenixqs']['principal'] =\
  "HTTP/#{node['fqdn']}@#{node[:bcpc][:hadoop][:kerberos][:realm]}" 
default['bcpc']['hadoop']['phoenix']['phoenixqs']['localuser'] = true
