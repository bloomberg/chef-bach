include_recipe 'bach_cluster::settings'

worker_node_count = node[:bach][:cluster][:node_count].to_i
total_node_count = worker_node_count + 2

#
# Chef-vault renders most data bag info unusable after destroying the
# chef client VMs.  As a result, it's best to delete the entire
# databag.
#
chef_data_bag 'os' do
  action :delete
  ignore_failure true
end

chef_data_bag 'configs' do
  action :delete
  ignore_failure true
end

1.upto(total_node_count).each do |n|
  vm_name = "bach-vm#{n}-b#{build_id}" # XXX: replace with helper!
  machine "#{vm_name}.bcpc.example.com" do
    chef_server chef_server_config_hash
    chef_environment node.chef_environment
    action :destroy
    ignore_failure true
  end
end

