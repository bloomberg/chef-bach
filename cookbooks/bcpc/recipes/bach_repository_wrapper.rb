require 'socket'


# Resolve any DNS address as we may not have working DNS on the cluster nodes (e.g. VM clusters)
uri_parts = URI.split(get_binary_server_url)
chef_server_fqdn = uri_parts[2]
begin
  uri_parts[2] = IPSocket::getaddress(uri_parts[2])
  # VM bootstrap will resolve themselves as localhost
  uri_parts[2] = node['bcpc']['bootstrap']['server'] if uri_parts[2] == '127.0.0.1'
rescue SocketError => e
  # we get the unhelpful error from getaddress, provide some context
  # "getaddrinfo: Name or service not known"
  Chef::Log.error("Got: e.message\nTrying to parse: #{uri_parts[2]}\n")
  raise
end
node.override['bach']['repository']['chef_server_fqdn'] = chef_server_fqdn
node.override['bach']['repository']['chef_url_base'] = URI::HTTP.new(*uri_parts)

# Setup node.run_state hashes for the Apt repos
node.run_state['bach'] = node.run_state.fetch(['bach'], {})
node.run_state['bach']['repository'] = node.run_state['bach'].fetch('repository', {})
node.run_state['bach']['repository']['gpg_private_key'] = get_config('private_key_base64', 'bootstrap-gpg', 'os')
node.run_state['bach']['repository']['gpg_public_key'] = get_config('bootstrap-gpg-public_key_base64')
