include_recipe 'bach_cluster::settings'

worker_node_count = node[:bach][:cluster][:node_count].to_i
total_node_count = worker_node_count + 2

chef_data_bag_item 'haproxy-stats' do
  data_bag 'os'
  chef_server chef_server_config_hash
  action :delete
end

chef_data_bag_item 'haproxy-stats_keys' do
  data_bag 'os'
  chef_server chef_server_config_hash
  action :delete
end

1.upto(total_node_count).each do |n|
  vm_name = "bach-vm#{n}-b#{build_id}" # XXX: replace with helper!
  machine "#{vm_name}.bcpc.example.com" do
    chef_server chef_server_config_hash
    chef_environment node.chef_environment
    action :destroy
  end
end

