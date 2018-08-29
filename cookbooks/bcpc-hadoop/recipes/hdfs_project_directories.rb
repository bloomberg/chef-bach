Chef::Resource::RubyBlock.send(:include, Bcpc_Hadoop::Helper)

ruby_block 'hdfs_projects_directories' do
  block { dir_creation('projects') }
end
