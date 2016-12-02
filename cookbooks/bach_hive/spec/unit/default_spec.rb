require 'spec_helper'

describe 'bach_hive::default' do
  context 'on Ubuntu' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(:platform => 'ubuntu',
                               :version => '12.04',
                               :step_into => ['alternatives']) do |node|
        env = Chef::Environment.new
        allow(node).to receive(:chef_environment).and_return('Test-Laptop')

        allow(Chef::Environment).to receive(:load).and_return(env)
      end.converge(described_recipe)
    end
    %w(hive webhcat hcat hive-hcatalog).each do |w|
      it "should create the #{w} directory"  do
        expect(chef_run).to create_directory("/etc/#{w}/conf.Test-Laptop").with(
          :owner => 'root',
          :group => 'root',
          :mode => 00755,
          :recursive => true
        )
      end
    end
  end
end
