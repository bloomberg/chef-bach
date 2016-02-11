include_recipe 'bach_cluster::settings'

worker_node_count = node[:bach][:cluster][:node_count].to_i
total_node_count = worker_node_count + 2

# Converge nodes with basic roles so they are available in node search.
1.upto(total_node_count).each do |n|
  vm_name = "bach-vm#{n}-b#{build_id}"
  vm_mgmt_ip = "10.0.101." + (3 + n).to_s
  vm_storage_ip = "10.0.101." + (19 + n).to_s
  vm_floating_ip = "10.0.101." + (35 + n).to_s
  my_netmask = '255.255.255.240'

  bach_cluster_node vm_name do
    cpus node[:bach][:cluster][:demo][:cpus]
    memory node[:bach][:cluster][:demo][:memory]

    management_ip vm_mgmt_ip
    management_netmask my_netmask

    storage_ip vm_storage_ip
    storage_netmask my_netmask

    floating_ip vm_floating_ip
    floating_netmask my_netmask

    run_list [
              'recipe[bach_common::apt_proxy]',
              'recipe[bach_common::binary_server]',
              'role[Basic]', 
             ]
    #complete true # Completely overwrite the runlist.
  end
end

# Force the chef server to rebuild its solr index.
rebuild_chef_index

# Wait for the head nodes to appear in the index.
ruby_block "wait-for-reindex" do
  block do
    wait_until_indexed("name:bach-vm1-b#{build_id}*",
                       "name:bach-vm2-b#{build_id}*")
  end
end

# Re-converge the ZK cluster (first three nodes) with added runlist items.
1.upto(3).each do |n|
  machine fqdn_for("bach-vm#{n}-b#{build_id}") do
    role 'BCPC-Kafka-Head-Zookeeper'
  end
end

# Reconverge remaining nodes (Kafka servers) with the complete runlist.
4.upto(total_node_count).each do |n|
  vm_name = fqdn_for("bach-vm#{n}-b#{build_id}") # XXX: replace with helper!
  machine vm_name do
    role 'BCPC-Kafka-Head-Server'
  end
end

# Re-run chef on every node by notifying machine resources.
1.upto(total_node_count).each do |n|
  vm_name = fqdn_for("bach-vm#{n}-b#{build_id}") # XXX: replace with helper!
  log "Re-converging #{vm_name}" do
    notifies :converge, "machine[#{vm_name}]", :immediately
  end
end
