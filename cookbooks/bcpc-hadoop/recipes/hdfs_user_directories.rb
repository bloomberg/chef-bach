Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)
Chef::Resource::RubyBlock.send(:include, Chef::Mixin::DeepMerge)

ruby_block "hdfs_user_directories" do
  block do
    # Default configuration for user directory creation
    user_dir_creation =
      node.default['bcpc']['hadoop']['dir_creation']['user']

    # Create directories for existing LDAP users and role accounts.
    # Add dirinfo entries for each user returned by LDAP queries.
    dirinfo = user_dir_creation['dirinfo']
    (cluster_users + cluster_roles).each do |user|
      space_quota = user_dir_creation["#{user}_space_quota"]
      ns_quota = user_dir_creation["#{user}_ns_quota"]

      dirinfo[user] = deep_merge({ owner: user }, dirinfo[user])
      dirinfo[user] = deep_merge(dirinfo[user], { space_quota: space_quota })
      dirinfo[user] = deep_merge(dirinfo[user], { ns_quota: ns_quota })
    end

    # Create user directories in /user.
    dir_creation('/user', user_dir_creation['defaults'], dirinfo)
  end
end
