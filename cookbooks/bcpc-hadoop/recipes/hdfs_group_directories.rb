Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)
Chef::Resource::RubyBlock.send(:include, Chef::Mixin::DeepMerge)

ruby_block "hdfs_group_directories" do
  block do
    # Default configuration for group directory creation
    groups_dir_creation =
      node['bcpc']['hadoop']['dir_creation']['groups']

    # Create directories for existing LDAP groups.
    # Add dirinfo entries for each group returned by LDAP queries.
    dirinfo =
      node.default['bcpc']['hadoop']['dir_creation']['groups']['dirinfo']
    (cluster_groups).each do |group|
      space_quota = groups_dir_creation["#{group}_space_quota"]
      ns_quota = groups_dir_creation["#{group}_ns_quota"]

      dirinfo[group] = deep_merge({ group: group }, dirinfo[group])
      dirinfo[group] = deep_merge(dirinfo[group], { space_quota: space_quota })
      dirinfo[group] = deep_merge(dirinfo[group], { ns_quota: ns_quota })
    end

    # Create group directories in /groups.
    dir_creation(
      '/groups',
      node['bcpc']['hadoop']['dir_creation']['groups']['defaults'],
      node['bcpc']['hadoop']['dir_creation']['groups']['dirinfo']
    )
  end
end
