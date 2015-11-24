#!/opt/chef/embedded/bin/ruby
# find specific resource on a certain node
# ARGV[0] : the node to search for specific resource
# ARGV[1] : the name of resouce to find
# ARGV[2] : resource ID to find

require_relative 'load_node_context'

# load chef configuration for node
LoadNodeContext.start

host_to_compile_for = ARGV[0]
this_host = Chef::Config[:node_name]

# load the ohai data of the node 
include Chef::DSL::DataQuery
ohai = Ohai::System.new
node_obj = []
while node_obj[0].nil?
  node_obj = LoadNodeContext.search_node(ARGV[0])
end
data = node_obj[0].node.automatic_attrs
ohai.data = data

# build the node
Chef::Config[:node_name] = host_to_compile_for
@client = Chef::Client.new()
@client.ohai = ohai
@client.policy_builder
Chef::Config[:node_name] = this_host
@client.load_node
@client.build_node

@client.sync_cookbooks
@client.setup_run_context

# select the needed resource from resource collection of the node
allResources = @client.node.run_context.resource_collection.all_resources

# case one, find if a certain resource with ID is on the node, nothing will return false
if ARGV[1] != nil && ARGV[2] != nil
  targetResources = resources.select{|resource| resource.resource_name == ARGV[1].to_sym && resource.name == ARGV[2]}
  if targetResources != nil && targetResources != []
    puts "TRUE"
  else
    puts "FALSE"
  end
# case two, find all the resources with a resource name on the node, nothing will return false 
elsif  ARGV[1] != nil && ARGV[2] == nil
  targetResources = resources.select{|resource| resource.resource_name == ARGV[1].to_sym }
  ids = []
  if targetResources != nil && targetResources != []
    targetResources.each do |resource|
      ids << resource.name
    end
    puts ids.join(",")
  else
    puts "FALSE"
  end
# case three, find all chef vault resources on the node, or return false
else
  resource_name = "chef_vault_secret"
  targetResources = allResources.select{|resource| resource.resource_name == resource_name.to_sym }
  vaults = []
  if targetResources != nil && targetResources != []
    targetResources.each do |resource|
      vaults << "#{resource.data_bag}::#{resource.name}"
    end
    puts vaults.join(",")
  else
    puts "FALSE"
  end
end
