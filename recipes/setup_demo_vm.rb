include_recipe 'bach_cluster::settings'

worker_node_count = node[:bach][:cluster][:node_count].to_i
total_node_count = worker_node_count + 2

# Pre-populate node entries so searches come up sane.
1.upto(total_node_count).each do |n|
  vm_name = "bach-vm#{n}-b#{build_id}"
  vm_fqdn = vm_name + '.' + node[:bcpc][:domain_name]
  vm_mgmt_ip = "10.0.101." + (3 + n).to_s
  vm_stor_ip = "10.0.101." + (19 + n).to_s
  vm_float_ip = "10.0.101." + (35 + n).to_s
  vm_attrs =
    { bcpc: { management: { ip: vm_mgmt_ip },
              storage: { ip: vm_mgmt_ip },
              floating: { ip: vm_mgmt_ip } },
      hostname: vm_name,
      fqdn: vm_fqdn }

  chef_node vm_fqdn do
    chef_server chef_server_config_hash
    chef_environment node.chef_environment
    attributes vm_attrs
  end
end

chef_client_config =
  <<-EOM.gsub(/^ {4}/,'')
    # Unfortunately, we are using an IP addr in the chef URL.
    # For at least the first run, SSL validation is disabled.
    verify_api_cert false
    ssl_verify_mode :verify_none
  EOM

head1_name = 'bach-vm1-b0'
head1_fqdn = head1_name + '.' + node[:bcpc][:domain_name]
head1_configuration = 
  "#{Chef::Config[:file_cache_path]}/#{head1_fqdn}.cfg"

template head1_configuration do
  source 'vm_configuration.rb.erb'
  mode 0644
  variables({
             name: head1_name,
             fqdn: head1_fqdn,
             memory: 3072,
             management_ip: '10.0.101.4',
             management_netmask: '255.255.255.240',
             # storage_ip: '10.0.101.4',
             # storage_netmask: '255.255.255.240',
             # floating_ip: '10.0.101.4',
             # floating_netmask: '255.255.255.240',
            })
end.run_action(:create)

machine head1_fqdn do
  add_machine_options(:vagrant_config => File.read(head1_configuration))
  add_machine_options(:convergence_options => 
    {
     :chef_config => chef_client_config,
     :ssl_verify_mode => :verify_none
    })
  chef_server chef_server_config_hash
  chef_environment node.chef_environment  
  files cert_files_hash
  recipe 'bach_common::apt_proxy'
  recipe 'bach_common::binary_server'
  role 'Basic'
  role 'BCPC-Hadoop-Head-Namenode-NoHA' # XXX: replace with helper!
  role 'BCPC-Hadoop-Head-HBase'
  #role 'Copylog'
  converge true
  complete true
end

head2_name = 'bach-vm2-b0'
head2_fqdn = head2_name + '.' + node[:bcpc][:domain_name]
head2_configuration = 
  "#{Chef::Config[:file_cache_path]}/#{head2_fqdn}.cfg"

template head2_configuration do
  source 'vm_configuration.rb.erb'
  mode 0644
  variables({
             name: head2_name,
             fqdn: head2_fqdn,
             memory: 3072,
             management_ip: '10.0.101.5',
             management_netmask: '255.255.255.240',
            })
end.run_action(:create)

# machine head2_fqdn do
#   add_machine_options(:vagrant_config => File.read(head2_configuration))
#   add_machine_options(:convergence_options => 
#     {
#      :chef_config => chef_client_config,
#      :ssl_verify_mode => :verify_none
#     })
#   chef_server chef_server_config_hash
#   chef_environment node.chef_environment  
#   files cert_files_hash
#   recipe 'bach_common::apt_proxy'
#   recipe 'bach_common::binary_server'
#   role 'Basic'
#   role 'BCPC-Hadoop-Head-Namenode-Standby' # XXX: replace with helper!
#   role 'BCPC-Hadoop-Head-MapReduce'
#   role 'BCPC-Hadoop-Head-Hive'
#   #role 'Copylog'
#   converge true
#   complete true
# end


# machine_batch do
#   1.upto(1).each do |n|
#     vm_name = "bach-vm#{n}-b#{build_id}" # XXX: replace with helper!
#     vm_fqdn = vm_name + '.' + node[:bcpc][:domain_name]
#     vm_management_ip = "10.0.101." + (3 + n).to_s # XXX: replace with helper!
#     vm_storage_ip = "10.0.101." + (19 + n).to_s # XXX: replace with helper!
#     vm_floating_ip = "10.0.101." + (35 + n).to_s # XXX: replace with helper!
#     netmask = "255.255.255.240"


#       chef_server chef_server_config_hash
#       chef_environment node.chef_environment
#       files cert_files_hash
#       recipe 'bach_common::binary_server'
#       action :converge
#     end
#   end
# end

# head2_name = "bach-vm2-b#{build_id}" # XXX: replace with helper!
# head2_fqdn = head2_name + '.' + node[:bcpc][:domain_name]
# machine head2_fqdn do
#   chef_server chef_server_config_hash
#   chef_environment node.chef_environment
#   role 'BCPC-Hadoop-Head-Namenode-Standby' # XXX: replace with helper!
#   role 'BCPC-Hadoop-Head-MapReduce'
#   role 'BCPC-Hadoop-Head-Hive'
#   role 'Copylog'
# end
  
# # Workers are converged in parallel.
# machine_batch do
#   # Skip 1 and 2, they are our head nodes.
#   3.upto(total_node_count).each do |n|
#     vm_name = "bach-vm#{n}-b#{build_id}" # XXX: replace with helper!
#     vm_fqdn = vm_name + '.' + node[:bcpc][:domain_name]
#     machine vm_fqdn do
#       chef_server chef_server_config_hash
#       chef_environment node.chef_environment
#       role 'BCPC-Hadoop-Worker' # XXX: replace with helper!
#       role 'Copylog'
#     end
#   end
# end
