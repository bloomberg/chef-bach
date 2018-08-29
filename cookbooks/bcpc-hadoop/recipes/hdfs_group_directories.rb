Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)
Chef::Resource::RubyBlock.send(:include, Chef::Mixin::DeepMerge)

ruby_block "hdfs_group_directories" do
  block do

    # Create directories for existing LDAP groups.
    (cluster_groups).each do |group|
      node.default['bcpc']['hadoop']['hdfs']['groups']['dirinfo'].default =
        deep_merge(
          node['bcpc']['hadoop']['hdfs']['groups']['dirinfo'],
          Hash[group, ['group', group]]
        )
    end

    dir_creation('groups')
  end
end
