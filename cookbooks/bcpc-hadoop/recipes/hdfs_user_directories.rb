Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

ruby_block "hdfs_user_directories" do
  block do
    # create the /user dirs: mode, dirs, home, perms
    dir_creation('user', cluster_users + cluster_roles, '/user', '0700')
  end
end
