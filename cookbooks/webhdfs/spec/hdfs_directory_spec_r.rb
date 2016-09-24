# RSpec testcase for hdfs_directory provider
# rspec cookbooks/webhdfs/spec/hdfs_directory_spec_r.rb --color --format documentation
#
require 'rspec'

require 'chef/platform'
require 'chef/run_context'
require 'chef/resource'
require 'chef/provider'
require 'chef/cookbook/metadata'
require 'chef/event_dispatch/dispatcher'
require 'webhdfs'

describe "Chef::Provider::HdfsDirectory" do
  before(:all) do
    md = Chef::Cookbook::Metadata.new
    md.from_file(File.join(File.dirname(File.dirname(__FILE__)), 'metadata.rb'))
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node,{}, @events)
    Chef::Resource::LWRPBase.build_from_file(md.name, File.join(File.dirname(File.dirname(__FILE__)), 'resources', 'hdfs_directory.rb'), @run_context)
    Chef::Provider::LWRPBase.build_from_file(md.name, File.join(File.dirname(File.dirname(__FILE__)), 'providers', 'hdfs_directory.rb'), @run_context)
  end
  before(:each) do  
    @host = 'host'
    @port = '14000'
    @user = 'tony'
    @path = '/tmp/test_new_case'
    @new_resource = Chef::Resource::WebhdfsHdfsDirectory.new(@path)
    allow(@new_resource).to receive(:hosts).and_return("#@host:#@port")
    allow(@new_resource).to receive(:user).and_return(@user)
    @provider = Chef::Provider::WebhdfsHdfsDirectory.new(@new_resource, @run_context)
  end

  describe "#load_current_resource" do
    before(:each) do
      allow_message_expectations_on_nil
      allow(nil).to receive(:slice).with(0,1).and_return("B")
      allow(nil).to receive(:slice).with(1..-1).and_return("cpc")
      @current_resource = Chef::Resource::WebhdfsHdfsDirectory.new(@path)
    end

    it "should create a current resource with the name of the new resource" do
      @client = 1
      allow(@provider).to receive(:get_active_host).and_return(@client)
      @provider.load_current_resource
    end

    it "cannot find the hostnode for hdfs" do
      @client = nil
      allow(@provider).to receive(:get_active_host).and_return(@client)
      expect { @provider.load_current_resource }.to raise_error(WebHDFS::Error)
    end

  end

  describe "#action_delete" do
    before(:each) do
      @current_resource = Chef::Resource::WebhdfsHdfsDirectory.new(@path)
    end
    
    it "delete the dir" do
      allow_message_expectations_on_nil
      allow(@provider).to receive(:dir_exists?).with(any_args()).and_return(true)
      allow(@client).to receive(:delete).with(any_args())
      @provider.action_delete
    end
  end

end

