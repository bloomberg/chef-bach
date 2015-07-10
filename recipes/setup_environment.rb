include_recipe 'bach_cluster::settings'

log "Node count: " + ENV['BACH_CLUSTER_NODE_COUNT'].to_s
log "Chef repo path: " + Chef::Config[:chef_repo_path]
log "Chef environment: " + node.chef_environment

template "#{Chef::Config[:chef_repo_path]}/environments/#{node.chef_environment}.json" do
  source 'environment.json.erb'
  mode 0664
  helpers(BachCluster::ChefHelpers)
  helpers(BachCluster::IP)
end
