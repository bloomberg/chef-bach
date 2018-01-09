node.force_default['bach']['repository']['gem_server'] = node['bcpc']['bootstrap']['server']
node.force_default['bach']['repository']['java'] = node['bcpc']['hadoop']['java']
node.force_default['bcpc']['bootstrap']['admin']['user'] = node.run_state[:bcpc_admin_user]
node.force_default['bach']['repository']['build']['user'] = node['bcpc']['bootstrap']['admin']['user']
node.force_default['bach']['repository']['chef_url_base'] = get_binary_server_url

# Setup node.run_state hashes for the Apt repos
node.run_state['bach'] = node.run_state.fetch(['bach'], {})
node.run_state['bach']['repository'] = node.run_state['bach'].fetch('repository', {})
node.run_state['bach']['repository']['gpg_private_key'] = get_config('private_key_base64', 'bootstrap-gpg', 'os')
node.run_state['bach']['repository']['gpg_public_key'] = get_config('bootstrap-gpg-public_key_base64')
