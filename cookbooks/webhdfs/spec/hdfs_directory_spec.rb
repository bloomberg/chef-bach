# hdfs_directory ChefSpec test recipe for action and attributes testing
# rspec cookbooks/webhdfs/spec/hdfs_directory_spec.rb --color --format documentation

require 'chefspec'

describe 'webhdfs::test_hdfs_directory' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }
  
  it 'creates a directory with attributes owner and group' do
    expect(chef_run).to create_webhdfs_hdfs_directory('/tmp/with_group_owner').with(
      owner: 'guest',
      group: 'supergroup',
      user: 'tony',
      hosts: 'host:14000',
    )
  end
  it 'create a directory with attribute owner' do
    expect(chef_run).to create_webhdfs_hdfs_directory('/tmp/only_with_owner').with(
      owner: 'hdfs'
    )
  end

  it 'creates a directory with attribute group' do
    expect(chef_run).to create_webhdfs_hdfs_directory('/tmp/only_with_group').with(
      group: 'hdfs'
    )
  end

  it 'creates a directory with attribute mode' do
    expect(chef_run).to create_webhdfs_hdfs_directory('/tmp/with_mode').with(
      mode: '650'
    )
  end

  it 'delete a directory' do
    expect(chef_run).to delete_webhdfs_hdfs_directory('/user/tony/with_delete').with(
      recursive: true  
    )
  end
end
