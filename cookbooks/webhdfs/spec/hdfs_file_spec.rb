# hdfs_directory ChefSpec test recipe for action and attributes testing
# rspec cookbooks/webhdfs/spec/hdfs_file_spec.rb --color --format documentation

require 'chefspec'

describe 'webhdfs::test_hdfs_file' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'creates a file with attributes owner and group' do
    expect(chef_run).to create_webhdfs_hdfs_file('/tmp/with_group_owner.txt').with(
      owner: 'guest',
      group: 'supergroup',
      user: 'tony',
      hosts: 'host:14000'
    )
  end
  it 'create a file with attribute owner' do
    expect(chef_run).to create_webhdfs_hdfs_file('/tmp/only_with_owner.txt').with(
      owner: 'hdfs'
    )
  end

  it 'creates a file with attribute group' do
    expect(chef_run).to create_webhdfs_hdfs_file('/tmp/only_with_group.txt').with(
      group: 'hdfs'
    )
  end

  it 'creates a file with attribute mode' do
    expect(chef_run).to create_webhdfs_hdfs_file('/tmp/with_mode.txt').with(
      mode: '650'
    )
  end

  it 'create a file with attribute content' do
    expect(chef_run).to create_webhdfs_hdfs_file('/tmp/with_content.txt').with(
      content: 'with content attributes to create a file on hdfs'
    )
  end

  it 'create a file if missing' do
    expect(chef_run).to create_if_missing_webhdfs_hdfs_file('/tmp/create_if_missing.txt')
  end

  it 'touch a file' do
    expect(chef_run).to touch_webhdfs_hdfs_file('/tmp/touch.txt')
  end

  it 'delete a file' do
    expect(chef_run).to delete_webhdfs_hdfs_file('/user/tony/with_delete.txt')
  end

end
