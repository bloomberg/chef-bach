Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

ruby_block 'hdfs_projects_directories' do
  block do 
    # Default configuration for projects directory creation
    projects_dir_creation = node['bcpc']['hadoop']['dir_creation']['projects']

    # Use the dirinfo structure specified in the default attribute.
    dirinfo = project_dir_creation['dirinfo']

    # Create projects directories in /projects.
    dir_creation('/projects', projects_dir_creation['defaults'], dirinfo)
  end
end
