# bach_cluster_policy

Recipes to enforce cluster-wide policies fiddled through attributes

## Usage for HBase

    # include this in your cookbook so that the policy resources are acted on
    node.default['bach_policies']['hbase'].tap do |hbase|
    end

    include_recipe 'bach_cluster_policy::hbase'
