Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)
Chef::Resource::RubyBlock.send(:include, Chef::Mixin::DeepMerge)

ruby_block "hdfs_user_directories" do
  block do

    # Create directories for existing LDAP users and role accounts.
    (cluster_users + cluster_roles).each do |user|
      node.default['bcpc']['hadoop']['hdfs']['user']['dirinfo'].default =
        deep_merge(
          node['bcpc']['hadoop']['hdfs']['user']['dirinfo'],
          Hash[user, ['owner', user]]
        )
    end

    dir_creation('user')
  end
end
