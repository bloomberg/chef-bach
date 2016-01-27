require 'spec_helper'

describe Bcpc_Hadoop::Helper do
  describe '#new_dir_creation' do
    let(:run_context) { Chef::RunContext.new(Chef::Node.new(), nil, nil) }
    let(:dummy_class) do
      Class.new do
        include Bcpc_Hadoop::Helper
      end
    end
    # LDAP info to pass in
    hdfs = "hdfs://test-hdfs"
    path = "compound/directory/here"
    user = "BiffGnarley"

    context 'no directory triggers directory creation' do

      let(:testout) { double(run_command: double(exitstatus: 1) ) }
      let(:createout) { double(run_command: double(exitstatus: 0)) }
      it 'tests for the directory existence' do
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          # we should have the directory path in the test command
          expect(arg1).to match(/^.*#{hdfs}\/#{path}.*$/)
          testout
        end
        expect(Mixlib::ShellOut).to receive(:new) do |arg1, arg2|
          # we should have the directory path in the creation command
          expect(arg1).to match(/^.*#{hdfs}\/#{path}.*$/)
          # we should have a mkdir in the creation command
          expect(arg1).to match(/^.*mkdir.*$/)
          # we should have a chown in the creation command
          expect(arg1).to match(/^.*chown.*$/)
          # we should have the user in the creation command
          expect(arg1).to match(/^.*#{user}.*$/)
          createout
        end
        # the command should not raise and should not complain
        expect(dummy_class.new.new_dir_creation(hdfs, path, user, "000", run_context)).to eq(nil)
      end
    end
  end
end
