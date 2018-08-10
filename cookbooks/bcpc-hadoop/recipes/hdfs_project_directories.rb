Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

ruby_block 'hdfs_projects_directories' do
  block do
    projects_dir_creation(node['bcpc']['hadoop']['hdfs']['projects']['dirinfo'])
  end
end
