Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

ruby_block "hdfs_group_directories" do
  block do
    # create the /groups dirs: mode, dirs, home, perms
    dir_creation('groups', cluster_groups, '/groups', '0770')
  end
end
