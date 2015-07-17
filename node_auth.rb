#!/opt/chef/embedded/bin/ruby

# authorize node to access the existed chef vault item
# ARGV[0] data_bag::vault_item
# ARGV[1] the node to be added to admin list to access vault_item

require_relative 'load_node_context'
require 'chef-vault'

# load the chef configuration for the node
LoadNodeContext.start

# if found the vault resource on the node, do updates
if ARGV[0] != "FALSE" && ARGV[0].include?("::")
  require 'chef-vault'
  vaults = ARGV[0].split(',')
  vaults.each do |vault|
    pair = vault.split('::')
    data_bag = pair[0]
    item = pair[1]
    # add the key of the node to vault item for access
    bag = Chef::DataBag.load(data_bag)
    if bag.has_key?("#{item}_keys")
      secret = ChefVault::Item.load(data_bag,item)
      secret.admins(ARGV[1],:add)
      secret.save
    end
  end
end

