Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

ruby_block 'hdfs_projects_directories' do
  block do 
    # Create projects directories in /projects.
    # Use the defaults and dirinfo specified in the attributes.
    dir_creation(
      '/projects',
      node['bcpc']['hadoop']['dir_creation']['projects']['defaults'],
      node['bcpc']['hadoop']['dir_creation']['projects']['dirinfo'],
    )
  end
end
