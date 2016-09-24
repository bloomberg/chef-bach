# hdfs_template ChefSpec test recipe for action create and attributes testing
# rspec cookbooks/webhdfs/spec/hdfs_template_spec.rb --color --format documentation
require 'webhdfs'
require 'chefspec'
require 'webhdfs/fileutils'

describe 'webhdfs::test_hdfs_template' do
  let(:chef_run) { ChefSpec::Runner.new(step_into: ['webhdfs_hdfs_template'] ).converge(described_recipe) }

  before :all do
    @host = 'host'
    @port = '14000'
    @user = 'tony'
    @hosts = "host:14000"
  end

  describe "#load_current_resource" do
    it 'throw exception when cannot find the namenode' do
      allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_raise(WebHDFS::Error)
      expect{ chef_run }.to raise_error(WebHDFS::Error)
    end
  end

  describe "#action_create" do
    before :each do
      @source = "hdfs_template_source.txt"
      @owner="guest"
      @client = double("@client")
      @path = "/tmp/hdfs_template.txt"
      allow(WebHDFS::Client).to receive(:new).with(any_args()).and_return(@client)
      dirmeta = {"type" => "DIRECTORY"}
      allow(@client).to receive(:stat).with("/").and_return(dirmeta)
    end

    it 'create a non-existed file from a template' do
      allow(WebHDFS::FileUtils).to receive(:set_server).with(any_args())
      allow(WebHDFS::FileUtils).to receive(:copy_from_local).with(any_args(), @path,{:overwrite=>true})
      filemeta1 = {}
      filemeta2 = {"type" => "FILE","owner" => "tony"}
      allow(@client).to receive(:stat).with(@path).and_return(filemeta1,filemeta2)
      allow(@client).to receive(:chown).with(@path,{:owner => @owner})
      expect(chef_run).to create_webhdfs_hdfs_template(@path).with(
        user: @user,
        hosts: "#@host:#@port",
        owner: 'guest',
        source: @source
      )
    end

    it 'failure of uploading file to hdfs' do
      filemeta = {}
      allow(WebHDFS::FileUtils).to receive(:set_server).with(any_args())
      allow(WebHDFS::FileUtils).to receive(:copy_from_local).with(any_args()).and_raise(WebHDFS::ServerError, "copy from local failed")
      allow(@client).to receive(:stat).with(@path).and_return(filemeta)
      expect(@client).not_to receive(:delete).with(any_args())
      expect{ chef_run }.to raise_error(WebHDFS::Error)
    end

    it 'failure of file chown on hdfs' do
      allow(WebHDFS::FileUtils).to receive(:set_server).with(any_args())
      allow(WebHDFS::FileUtils).to receive(:copy_from_local).with(any_args(), @path, {:overwrite => true})
      filemeta1 = {}
      filemeta2 = {"type" => "FILE","owner" => "tony"}
      allow(@client).to receive(:stat).with(@path).and_return(filemeta1,filemeta2)
      allow(@client).to receive(:chown).with(any_args()).and_raise(WebHDFS::ServerError, "Permission defined for user #@user to chown file #@path")
      allow(@client).to receive(:delete).with(any_args())
      expect{ chef_run }.to raise_error(WebHDFS::Error)
    end
  end
end

describe 'webhdfs::test_hdfs_template2' do
  let(:chef_run) { ChefSpec::Runner.new(step_into: ['webhdfs_hdfs_template'] ).converge(described_recipe) }

  before :all do
    @host = 'host'
    @port = '14000'
    @user = 'tony'
    @hosts = "host:14000"
  end

  describe "#action_create_if_missing" do
    before :each do
      @source = "hdfs_template_source.txt"
      @owner="guest"
      @client = double("@client")
      @path_c = double("path")
      @path_c = "/tmp/hdfs_template_cim.txt"
      allow(WebHDFS::Client).to receive(:new).with(any_args()).and_return(@client)
      dirmeta = {"type" => "DIRECTORY"}
      allow(@client).to receive(:stat).with("/").and_return(dirmeta)
    end
    
    it 'create a file by template when not existed' do
      allow(WebHDFS::FileUtils).to receive(:set_server).with(any_args())
      allow(WebHDFS::FileUtils).to receive(:copy_from_local).with(any_args(), @path_c)
      filemeta1 = {}
      filemeta2 = {"type" => "FILE","owner" => "tony"}
      allow(@client).to receive(:stat).with(@path_c).and_return(filemeta1,filemeta2)
      allow(@client).to receive(:chown).with(@path_c,{:owner => @owner})
      expect(chef_run).to create_if_missing_webhdfs_hdfs_template(@path_c).with(
        user: @user,
        hosts: "#@host:#@port",
        owner: 'guest',
        source: @source
      )
    end

    it 'file already existed do nothing' do
      filemeta = {"type" => "FILE","owner" => "tony"}
      allow(@client).to receive(:stat).once.with(@path_c).and_return(filemeta)
      expect(WebHDFS::FileUtils).not_to receive(:copy_from_local)
      expect(chef_run).to create_if_missing_webhdfs_hdfs_template(@path_c).with(
        user: @user,
        hosts: "#@host:#@port",
        owner: 'guest',
        source: @source
      )
    end
  end
end

describe 'webhdfs::test_hdfs_template3' do
  let(:chef_run) { ChefSpec::Runner.new(step_into: ['webhdfs_hdfs_template'] ).converge(described_recipe) }

  before :all do
    @host = 'host'
    @port = '14000'
    @user = 'tony'
    @hosts = "host:14000"
  end
  describe "#action_delete" do
    before :each do
      @path = "/tmp/hdfs_template_d.txt"
      @client = double("@client")
      allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_return(@client)
      dirmeta = {"type" => "DIRECTORY"}
      allow(@client).to receive(:stat).with("/").and_return(dirmeta)
    end

    it 'delete the file when the file exist' do
      filemeta = {"type" => "FILE","owner" => "tony"}
      allow(@client).to receive(:stat).with(@path).and_return(filemeta)
      expect(@client).to receive(:delete).with(any_args())
      expect(chef_run).to delete_webhdfs_hdfs_template(@path).with(
        user: @user,
        hosts: "#@host:#@port"
      )
    end

    it 'do nothing when file is not existed' do
      filemeta = {}
      allow(@client).to receive(:stat).with(@path).and_return(filemeta)
      expect(@client).not_to receive(:delete).with(any_args())
      expect(chef_run).to delete_webhdfs_hdfs_template(@path).with(
        user: @user,
        hosts: "#@host:#@port"
      )
    end
  end
end

describe 'webhdfs::test_hdfs_template4' do
  let(:chef_run) { ChefSpec::Runner.new(step_into: ['webhdfs_hdfs_template'] ).converge(described_recipe) }

  before :all do
    @host = 'host'
    @port = '14000'
    @user = 'tony'
    @hosts = "host:14000"
  end

  describe "#action_touch" do
    before :each do
      @path = "/tmp/hdfs_template_t.txt"
      @client = double("@client")
      allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_return(@client)
      dirmeta = {"type" => "DIRECTORY"}
      allow(@client).to receive(:stat).with("/").and_return(dirmeta)
    end

    it 'touch a file when it exists' do
      filemeta = {"type" => "FILE","owner" => "tony"}
      allow(@client).to receive(:stat).with(@path).and_return(filemeta)
      expect(@client).to receive(:touch).with(any_args())
      expect(chef_run).to touch_webhdfs_hdfs_template(@path).with(
        user: @user,
        hosts: "#@host:#@port"
      )
    end

    it 'do nothing when a file is not existed' do
      filemeta = {}
      allow(@client).to receive(:stat).with(@path).and_return(filemeta)
      expect(@client).not_to receive(:touch).with(any_args())
      expect(chef_run).to touch_webhdfs_hdfs_template(@path).with(
        user: @user,
        hosts: "#@host:#@port"
      )
    end
  end
end

