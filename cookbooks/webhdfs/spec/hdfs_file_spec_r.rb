# RSpec testcase for hdfs_directory provider
# rspec cookbooks/webhdfs/spec/hdfs_file_spec_r.rb --color --format documentation
#
require 'rspec'

require 'chef/platform'
require 'chef/run_context'
require 'chef/resource'
require 'chef/provider'
require 'chef/cookbook/metadata'
require 'chef/event_dispatch/dispatcher'
require 'webhdfs'

describe "Chef::Provider::HdfsFile" do
  
  before(:all) do
    md = Chef::Cookbook::Metadata.new
    md.from_file(File.join(File.dirname(File.dirname(__FILE__)), 'metadata.rb'))
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node,{}, @events)
  
    Chef::Resource::LWRPBase.build_from_file(md.name, File.join(File.dirname(File.dirname(__FILE__)), 'resources', 'hdfs_file.rb'), @run_context)
    Chef::Provider::LWRPBase.build_from_file(md.name, File.join(File.dirname(File.dirname(__FILE__)), 'providers', 'hdfs_file.rb'), @run_context)
  end
  before(:each) do  
    @host = 'host'
    @port = '14000'
    @user = 'tony'
    @path = '/tmp/test_new_case.txt'
    
    @new_resource = Chef::Resource::WebhdfsHdfsFile.new(@path)
    allow(@new_resource).to receive(:hosts).and_return("#@host:#@port")
    allow(@new_resource).to receive(:user).and_return(@user)
    @provider = Chef::Provider::WebhdfsHdfsFile.new(@new_resource, @run_context)
  end

  describe "#load_current_resource" do
    before :each do
      allow_message_expectations_on_nil
      allow(nil).to receive(:slice).with(0,1).and_return("B")
      allow(nil).to receive(:slice).with(1..-1).and_return("cpc")
    end     
    it "should create a current resource with the name of the new resource" do
      @client = 1
      allow(@provider).to receive(:get_active_host).with(any_args()).and_return(true)
      @provider.load_current_resource
    end

    it "cannot find the hostnode for hdfs" do
      allow(@provider).to receive(:get_active_host).with(any_args()).and_return(nil)
      expect { @provider.load_current_resource }.to raise_error(WebHDFS::Error)
    end

  end

  describe "#action_create" do
    before(:each) do
      allow_message_expectations_on_nil
      allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_return(@client)
      @provider.instance_variable_set("@path",@path)
      @owner = 'tony'
      @filemeta = {'owner' => 'guest'}
      @provider.instance_variable_set("@owner",@owner)
      allow(@client).to receive(:create).with(any_args())
      allow(@client).to receive(:stat).with(@path).and_return(@filemeta)
      allow(@client).to receive(:chown).with(any_args())
    end

    it "create the file" do
      allow_message_expectations_on_nil
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(false)
      @provider.instance_variable_set("@filemeta",@filemeta)
      expect(@client).to receive(:create).with(any_args())
      expect(@client).to receive(:stat).with(@path).and_return({"owner" => "guest"})
      expect(@client).to receive(:chown).with(@path,{:owner => @owner})
      @provider.action_create
    end

    it "update the file by overwrite if it is existed" do
      allow_message_expectations_on_nil
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(true)
      filemeta = @filemeta
      filemeta["group"] = "supergroup"
      group = "wiredgroup"
      @provider.instance_variable_set("@filemeta",filemeta)
      @provider.instance_variable_set("@group", group)
      
      expect(@client).to receive(:chown).with(@path, { :owner => @owner, :group => group })
      @provider.action_create
    end

    it "create file on hdfs failed" do
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(false)
      allow(@client).to receive(:create).with(any_args()).and_raise(WebHDFS::ServerError)
      expect{ @provider.action_create }.to raise_error(WebHDFS::ServerError)
    end

    it "chown file during creation failed (permission denied!)" do
      allow_message_expectations_on_nil
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(false)
      @provider.instance_variable_set("@filemeta",@filemeta)
      allow(@client).to receive(:chown).with(any_args()).and_raise(WebHDFS::ServerError,"Permission denied for user #@user to create #@path")
      allow(@client).to receive(:delete).with(any_args())

      expect{ @provider.action_create }.to raise_error(WebHDFS::ServerError)
    end
  end

  describe "#action_create_if_missing" do
    before(:each) do
      allow_message_expectations_on_nil
      #allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_return(@client)
      @provider.instance_variable_set("@path",@path)
      @owner = 'tony'
      @filemeta = {'owner' => 'guest'}
      @provider.instance_variable_set("@owner",@owner)
      allow(@client).to receive(:create).with(any_args())
      allow(@client).to receive(:stat).with(@path).and_return(@filemeta)
      allow(@client).to receive(:chown).with(any_args())
    end

    it "create the file on hdfs when it does not exist" do
      allow_message_expectations_on_nil
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(false)
      expect(@client).to receive(:create).with(any_args())
      expect(@client).to receive(:stat).with(@path).and_return({"owner" => "guest"})
      @provider.action_create_if_missing 
    end

    it "do nothing when a file has already existed" do
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(true)
      expect(@client).not_to receive(:create).with(any_args())
      @provider.action_create_if_missing
    end
  end

  describe "#action_touch" do
    before(:each) do
      allow_message_expectations_on_nil
      #allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_return(@client)
      @provider.instance_variable_set("@path",@path)
      @filemeta = {'owner' => 'guest'}
      allow(@client).to receive(:create).with(any_args())
      allow(@client).to receive(:stat).with(@path).and_return(@filemeta)
      allow(@client).to receive(:chown).with(any_args())
    end
    it "touch the file on hdfs when it exists" do
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(true)
      expect(@client).to receive(:touch).with(any_args())
      @provider.action_touch
    end
    
    it "do nothing when file is not existed" do
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(false)
      expect(@client).not_to receive(:touch).with(any_args())
      @provider.action_touch
    end

  end
  
  describe "#action_delete" do
    before(:each) do
      allow_message_expectations_on_nil
      @current_resource = Chef::Resource::WebhdfsHdfsFile.new(@path)
      #allow(WebHDFS::Client).to receive(:new).with(@host, @port, @user).and_return(@client)
      allow(@client).to receive(:delete)
    end
    
    it "delete the file when the file exist" do
      allow_message_expectations_on_nil
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(true)
      expect(@client).to receive(:delete).with(any_args())
      @provider.action_delete
    end

    it "do mothing when file is not existed" do
      allow(@provider).to receive(:file_exists?).with(any_args()).and_return(false)
      expect(@client).not_to receive(:delete).with(any_args())
      @provider.action_delete
    end

  end

end

