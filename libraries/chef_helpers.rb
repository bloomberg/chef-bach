module BachCluster
  module ChefHelpers
    def bootstrap_fqdn
      bootstrap_vm_name + '.' + node['bcpc']['domain_name']
    end

    def bootstrap_ip
      node[:bcpc][:bootstrap][:server]
    end

    def bootstrap_vm_name
      "bach-vm-bootstrap-b#{build_id}"
    end

    def build_id
      ENV['BUILD_ID'] || '0'
    end

    def cert_files_hash 
      #
      # Define a hash to copy any certificates from the build host.
      #
      # Keys are remote paths, on the bootstrap node
      # Values are local paths, on the hypervisor host.
      #
      local_cert_dir = node['bach']['cluster']['certificates_path']
      local_files = Dir.glob("#{local_cert_dir}/*.crt")
      ca_certs = local_files.map{ |f| 
        { "/usr/local/share/ca-certificates/#{File.basename(f)}" => f } 
      }.reduce{ |accumulator,hash| accumulator.merge(hash) } || {}

      chef_cert_hash = 
        if(File.exists?(Chef::Config['trusted_certs_dir'] +
                        "/#{bootstrap_fqdn}.crt"))
          { "/etc/chef/trusted_certs/#{bootstrap_fqdn}.crt" => 
           "#{Chef::Config[:trusted_certs_dir]}/#{bootstrap_fqdn}.crt" }
        else
          {}
        end
            
      ca_certs.merge(chef_cert_hash)
    end

    def chef_client_attributes
    end

    def chef_server_attributes
      { 
       'chef-server' => { 
                         'api_fqdn' => bootstrap_fqdn,
                         'configuration' => chef_server_config_string
                        } 
      }
    end

    # This is the configuration *hash* for use by 'machine' resources.
    def chef_server_config_hash
      {
        chef_server_url: chef_server_url,
        options: {
          client_name: 'bach',
          signing_key_filename: "#{cluster_data_dir}/bach_user.pem"
        }
      }
    end

    # This is the configuration *string* used by the chef-server cookbook.
    def chef_server_config_string
      <<-EOM.gsub(/^ {8}/,'')
        # Apache serves repos on 80, so disable chef-server's port 80 listener.
        nginx['non_ssl_port'] = false
        nginx['enable_non_ssl'] = false
      EOM
    end

    def chef_server_url
      "https://#{bootstrap_ip}/organizations/" + 
        node['bach']['cluster']['organization']['name']
    end

    def cluster_data_dir
      "#{Chef::Config[:chef_repo_path]}/.chef"
    end

    def fqdn_for(name)
      if name.end_with?(node[:bcpc][:domain_name])
        name
      else
        name + '.' + node[:bcpc][:domain_name]
      end
    end

    def render_knife_config
      template File.join(cluster_data_dir, 'knife.rb') do
        variables({
                   chef_server_url:
                     "https://#{bootstrap_ip}/organizations/" +
                     node['bach']['cluster']['organization']['name'],
                   user_name: node['bach']['cluster']['user']['name'],
                   client_key: "#{cluster_data_dir}/bach_user.pem",
                   validation_client_name: 
                     node['bach']['cluster']['organization']['name'] + 
                       '-validator',
                   validation_key: 
                     "#{cluster_data_dir}/bach_validator.pem",
                  })
      end
    end
  end
end

[ 
 Chef::Recipe,
 Chef::Resource
].each do |klass| 
  klass.send(:include, BachCluster::ChefHelpers)
end
