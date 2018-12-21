include_recipe 'bcpc::admin_base'

chef_data_bag 'ssh_host_keys'

key_types = %w{dsa ecdsa ed25519 rsa}

fetch_all_nodes.each do |host|
  fqdn = "#{host[:hostname]}.#{host[:dns_domain]}"
  chef_vault_secret fqdn do
    data_bag 'ssh_host_keys'
    admins Chef::Config.node_name
    raw_data lazy {
      key_types.map do |key_type|
        key_content = nil
        Dir.mktmpdir do |d|
          shell_out! "ssh-keygen -t #{key_type} -f #{d}/key"
          key_content = File.read "#{d}/key"
        end
        [key_type, key_content]
      end.to_h
    }
    search "fqdn:#{fqdn}"
    action :create_if_missing
  end
end
