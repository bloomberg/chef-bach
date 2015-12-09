include_recipe 'bach_cluster::settings'

# Long term:
# - Provision a test cluster for smoke testing first, faster
# - Run a second set of tests with the whole pxe process if the first passes!
# - get that stuff working with the pxe process
# - use vde instead of hostonlyif, so we can dockerize?

networks = get_networks(build_id: build_id,
                        netblock: IPAddress("10.0.101.0/24"))

ip_hash = get_ip_hash(build_id: build_id,
                      node_count: 5,
                      networks: networks)

(bootstrap_management, bootstrap_storage, bootstrap_floating) = 
  ip_hash["bach-vm-bootstrap-b#{build_id}"].map{ |s| IPAddress(s) }

(hypervisor_management, hypervisor_storage, hypervisor_floating) = 
  ip_hash['hypervisor'].map{ |s| IPAddress(s) }

bootstrap_vm_configuration = <<-EOM 
  config.vm.hostname = "#{bootstrap_fqdn}"

  config.vm.network :private_network, 
    ip: "#{bootstrap_management.address}", 
    netmask: "#{bootstrap_management.netmask}", 
    adapter_ip: "#{hypervisor_management.address}"

  config.vm.network :private_network,
    ip: "#{bootstrap_storage.address}", 
    netmask: "#{bootstrap_storage.netmask}", 
    adapter_ip: "#{hypervisor_storage.address}"

  config.vm.network :private_network, 
    ip: "#{bootstrap_floating.address}", 
    netmask: "#{bootstrap_floating.netmask}", 
    adapter_ip: "#{hypervisor_floating.address}"

  config.vm.provider :virtualbox do |vb|
     vb.gui = false
     vb.name = "#{bootstrap_vm_name}"
     vb.cpus = 4
     vb.customize ["modifyvm", :id, "--memory", "3072"]
     vb.customize ["modifyvm", :id, "--nictype2", "82543GC"]
     vb.customize ["modifyvm", :id, "--largepages", "on"]
     vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
     vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
     vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
     vb.customize ["modifyvm", :id, "--ioapic", "on"]
   end
EOM

machine bootstrap_fqdn do
  add_machine_options :vagrant_config => bootstrap_vm_configuration
  chef_environment node.chef_environment
  attributes chef_server_attributes
  complete true # overwrite run_list and pre-existing attributes.
  files cert_files_hash
  recipe 'bach_bootstrap::chef-server'
  action :converge
end

directory cluster_data_dir do
  action :create
end

# Fetch our user, client, and server certs from the provisioned Chef Server
machine_file '/home/vagrant/bach_user.pem' do
  machine bootstrap_fqdn
  mode '0644'
  local_path "#{cluster_data_dir}/bach_user.pem"
  action :download
end

machine_file '/home/vagrant/bach_validator.pem' do
  machine bootstrap_fqdn
  mode '0644'
  local_path "#{cluster_data_dir}/bach_validator.pem"
  action :download
end

%w{ data_bag environment node role trusted_cert }.each do |item|
  directory Chef::Config["#{item}_path"]
end

machine_file "/var/opt/opscode/nginx/ca/#{bootstrap_fqdn}.crt" do
  machine bootstrap_fqdn
  mode '0644'
  local_path "#{Chef::Config.trusted_certs_dir}/#{bootstrap_fqdn}.crt"
  action :download
end

# Generate a valid knife configuration
render_knife_config

directory File.join(cluster_data_dir,'data_bags') do
  action :create
end

knife_environment = {'http_proxy'  => nil,
                     'https_proxy' => nil,
                     'HTTP_PROXY'  => nil,
                     'HTTPS_PROXY' => nil,
                     'KNIFE_HOME'  => cluster_data_dir}

execute 'upload-cookbooks' do
  command "bundle exec knife cookbook -VV upload --all --cookbook-path #{Chef::Config[:cookbook_path]} --force"
  environment knife_environment
  cwd File.dirname(__FILE__)
end

execute 'upload-environments' do
  command "bundle exec knife upload -VV --force --chef-repo-path #{Chef::Config[:chef_repo_path]} environments"
  environment knife_environment
  cwd Chef::Config[:chef_repo_path]
end

execute 'upload-roles' do
  command "bundle exec knife upload -VV --force --chef-repo-path #{Chef::Config[:chef_repo_path]} roles"
  environment knife_environment
  cwd Chef::Config[:chef_repo_path]
end

# Fix ACLs: allow clients to edit data bags like they did in Chef 11.x
# https://www.chef.io/blog/2014/11/10/security-update-hosted-chef/
execute "update-bach-data-bag-acls" do
  command 'bundle exec knife acl add group clients containers data ' +
    'create,read,update'
  environment knife_environment
  cwd Chef::Config[:chef_repo_path]
end

# Allow clients to read each other.
execute "update-bach-client-acls" do
  command 'bundle exec knife acl add group clients containers clients read'
  environment knife_environment
  cwd Chef::Config[:chef_repo_path]
end

# This is different from other nodes because it has proxy config.
bootstrap_chef_client_config =
  <<-EOM.gsub(/^ {4}/,'')
    no_proxy "#{bootstrap_fqdn},#{bootstrap_ip},127.0.0.1"
    verify_api_cert false
    ssl_verify_mode :verify_none
  EOM

if(node['bach']['http_proxy'])
   bootstrap_chef_client_config +=
     "http_proxy \"#{node['bach']['http_proxy']}\"\n"
end

if(node['bach']['https_proxy'])
   bootstrap_chef_client_config +=
     "https_proxy \"#{node['bach']['https_proxy']}\"\n"
end   

#
# Re-provision the bootstrap VM as its own client.
#
# The first chef run is meant only to get us a client key on the Chef server.
#
machine bootstrap_fqdn do
  chef_server chef_server_config_hash
  add_machine_options :convergence_options => {
    :chef_config => bootstrap_chef_client_config,
    :ssl_verify_mode => :verify_none
  }
  role 'Basic'
  complete false
end

#
# Pre-populate the cobbler secrets so that our user account is
# able to read them.  This requirement is a bug in Chef:
#
# https://github.com/chef/chef-server/issues/20
#
web_password = rand(36**24).to_s(36)
root_password = rand(36**24).to_s(36)
#
# The $6$xxxxxx argument is an undocumented, "platform-dependent"
# behavior that creates a salted SHA512 password hash.
#
# I don't know where this behavior does or doesn't work.
#
crypted_root_password = root_password.crypt('$6$' + rand(36**8).to_s(36))

execute "create-cobbler-secret" do
  command "knife vault create os cobbler " +
    "'{\"web-password\": \"#{web_password}\", " +
    "  \"root-password\": \"#{root_password}\", " +
    "  \"root-password-salted\": \"#{crypted_root_password}\"}' " +
    "-S '*:*' -A bach"
  environment knife_environment
  cwd Chef::Config[:chef_repo_path]

  #
  # The guard_interpreter is set to force the guard to inherit
  # properties from the execute resource.
  #
  guard_interpreter :bash
  not_if 'knife vault show os cobbler'
end

# Provision with a complete role.
machine bootstrap_fqdn do
  chef_server chef_server_config_hash
  add_machine_options :convergence_options => {
    :chef_config => bootstrap_chef_client_config,
    :ssl_verify_mode => :verify_none
  }
  role 'BCPC-Bootstrap'
  complete false
end
