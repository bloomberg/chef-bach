# chefspec to mock the senario of webhdfs failure: connection, create dir
# rspec cookbooks/webhdfs/spec/hdfs_dir_failure_spec.rb --color
#
require 'webhdfs'
require 'chefspec'

describe 'webhdfs::test_webhdfs_dir_fail' do
  
  let(:chef_run) { ChefSpec::Runner.new(step_into: ['webhdfs_hdfs_directory'] ).converge(described_recipe) }
  
  before :all do
    @host = "host"
    @port = "14000"
    @user = "tony"
    @path = '/tmp/webhdfs_failure'
  end

  it 'throw exception when cannot find the namenode' do
    allow(WebHDFS::Client).to receive(:new)
      .with(@host, @port, @user).and_raise(WebHDFS::Error)
    expect{
        chef_run
    }.to raise_error(WebHDFS::Error)
  end
  
  it "failed directory creation (permission denied)" do
    client = double("@client")
    allow(WebHDFS::Client).to receive(:new).with(
      @host,
      @port,    
      @user
    ).and_return(client)

    dirmeta = double("@dirmeta")
    dirmeta = {"type" => "DIRECTORY"}
    
# first time call client.stat() to make sure accessed to hdfs rightly
    allow(client).to receive(:stat).with("/").and_return(dirmeta)
# second time call client.stat() to check if the path is existed or not, should not existed
    allow(client).to receive(:stat).with(@path).and_raise(WebHDFS::ServerError,"#{ @path } does not exit")
    allow(client).to receive(:mkdir).with(@path, {:permission => ['755']}).and_raise(WebHDFS::ServerError, "Permission denied for user #@user to create #@path")
    #expect(chef_run).to create_webhdfs_hdfs_directory(@path).with(
    #  user: @user,
    #  hosts: "#@host:#@port",
    #  owner: 'guest'
    #).and_raise(WebHDFS::ServerError, "Permission denied for user #@user to create #@path")
    expect{
        chef_run
    }.to raise_error(WebHDFS::ServerError)
  end

  it 'failed directory chown (permission denied)' do
    client = double("@client")
    allow(WebHDFS::Client).to receive(:new).with(
      @host,
      @port,    
      @user
    ).and_return(client)

    dirmeta = double("@dirmeta")
    dirmeta = {"type" => "DIRECTORY", "owner" => 'tony'}
# call client.stat() to make sure accessed to hdfs rightly twice
    allow(client).to receive(:stat).with(any_args()).and_return(dirmeta)
    allow(client).to receive(:chown).with(any_args()).and_raise(WebHDFS::ServerError, "Permission denied for user #@user to chown operation on #@path")
   # expect(chef_run).to create_webhdfs_hdfs_directory(@path).with(
   #   user: @user,
   #   hosts: "#@host:#@port",
   #   owner: 'guest'
   # )
    expect{
        chef_run
    }.to raise_error(WebHDFS::ServerError)
  end
end

