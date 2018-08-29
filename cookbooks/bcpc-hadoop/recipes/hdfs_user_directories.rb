Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)
Chef::Resource::RubyBlock.send(:include, Chef::Mixin::DeepMerge)

ruby_block "hdfs_user_directories" do
  block do

    # Create directories for existing LDAP users and role accounts.
    dirinfo = node.default['bcpc']['hadoop']['hdfs']['user']['dirinfo']
    (cluster_users + cluster_roles).each do |user|
      dirinfo[user] = deep_merge(dirinfo[user], { owner: user })
    end

    dir_creation('user')
  end
end
