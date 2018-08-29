Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)
Chef::Resource::RubyBlock.send(:include, Chef::Mixin::DeepMerge)

ruby_block "hdfs_group_directories" do
  block do

    # Create directories for existing LDAP groups.
    dirinfo = node.default['bcpc']['hadoop']['hdfs']['groups']['dirinfo']
    (cluster_groups).each do |group|
      dirinfo[group] = deep_merge(dirinfo[group], { group: group })
    end

    dir_creation('groups')
  end
end
