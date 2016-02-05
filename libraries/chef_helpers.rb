module BachCluster
  module ChefHelpers
    def bootstrap_fqdn
      fqdn_for(bootstrap_vm_name)
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

    def chef_client_config
    <<-EOM.gsub(/^ {6}/,'')
      # Unfortunately, we are using an IP addr in the chef URL.
      # For at least the first run, SSL validation is disabled.
      verify_api_cert false
      ssl_verify_mode :verify_none

      # chef-provisioning doesn't automatically get this.
      no_proxy '#{bootstrap_fqdn},#{bootstrap_ip},' +
               '#{node[:bcpc][:management][:vip]},localhost'
    EOM
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

    def cobbler_root_password      
      require 'json'
      require 'mixlib/shellout'
      
      vault_command =
        Mixlib::ShellOut.new('bundle', 'exec',
                             'knife', 'vault', 'show',
                             'os', 'cobbler',
                             '-F', 'json',
                             '-p', 'all',
                             '-m', 'client',
                             :env => knife_environment,
                             :cwd => Chef::Config[:chef_repo_path])
      
      vault_command.run_command
      
      if !vault_command.status.success?
        raise 'Could not retrieve cobbler password!\n' +
          vault_command.stdout + '\n' +
          vault_command.stderr
      end
      
      JSON.parse(vault_command.stdout)['root-password']
    end

    def fqdn_for(name)
      if name.end_with?(node[:bcpc][:domain_name])
        name
      else
        name + '.' + node[:bcpc][:domain_name]
      end
    end

    def install_sh_url
      # This script is created by the bach_repository::chef recipe.
      "http://#{bootstrap_ip}/chef-install.sh"
    end

    def knife_environment
      {'http_proxy'  => nil,
       'https_proxy' => nil,
       'HTTP_PROXY'  => nil,
       'HTTPS_PROXY' => nil,
       'KNIFE_HOME'  => cluster_data_dir}
    end

    def rebuild_chef_index
      # Force the chef server to rebuild its solr index.
      # (Index rebuild via knife is no longer supported.)
      machine_execute 'chef-server-reindex' do
        machine bootstrap_fqdn
        chef_server chef_server_config_hash
        command "chef-server-ctl reindex " +
          node[:bach][:cluster][:organization][:name]
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

    def wait_until_indexed(*target_vms)
      #
      # We're calling out to knife instead of using the Chef API because
      # I couldn't figure out how to call Cheffish by hand from a ruby
      # block.
      #
      # This is definitely the wrong way to do this.
      #
      # We created a .chef/knife.rb when we set up the bootstrap server,
      # so knife is already configured.
      #
      def find_client(string)
        command_string = 
          'env -u http_proxy -u https_proxy -u no_proxy ' +
          ' -u HTTP_PROXY -u HTTPS_PROXY -u NO_PROXY ' +
          "knife search client '#{string}' " +
          '2>&1 >/dev/null | grep -v 0 | grep found'

        Chef::Log.debug("Running: #{command_string}")

        cmd = Mixlib::ShellOut.new(command_string,
                                   :cwd => Chef::Config[:chef_repo_path])
        r = cmd.run_command
        Chef::Log.debug("Result: #{r.inspect}")
        !cmd.error?
      end
      
      target_vms.each do |search_string|
        until(find_client(search_string))
          Chef::Log.info("Waiting for #{search_string} to appear in index")
          sleep 10
        end
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
