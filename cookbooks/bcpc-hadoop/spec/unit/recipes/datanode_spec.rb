require 'spec_helper'

describe 'bcpc-hadoop::datanode' do
  let(:dummy_class) do
    Class.new do
      include Bcpc_Hadoop::Helper
    end
  end

  # load a bcpc-hadoop recipe to test cookbook attributes cover business rules
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      Fauxhai.mock(platform: 'ubuntu', version: '12.04')
      node.set['memory']['total'] = 1024
      node.set['cpu']['total'] = 1
      allow_any_instance_of(Chef::Recipe).to receive(:make_config).and_return(lambda { true })

      node.set[:bcpc][:hadoop][:mounts] = [0, 1]
      stub_search("node", "recipes:bcpc-hadoop\\:\\:zookeeper_server AND chef_environment:#{node.environment}").and_return([node])
      $dbi = stub_data_bag_item('configs', node.environment).and_return({ 
                           'id' => 'POB2-GEN',
                           'mysql-hive-password' => 'sekret',
                           'mysql-hive-table-stats-user' => 'name',
                           'mysql-hive-table-stats-password' => 'sekret_too'
                         }).block
    end.converge("recipe[bcpc-hadoop::datanode]")

#      node.set["bcpc"]["hadoop"]["distribution"]["version"] = 'HDP'
#      node.set["bcpc"]["hadoop"]["distribution"]["release"] = '2.3.4.0-3485'
#      node.set["bcpc"]["hadoop"]["distribution"]["active_release"] = node["bcpc"]["hadoop"]["distribution"]["release"]
  end
  let(:node) { chef_run.node }

  %w{hadoop-2-3-4-0-3485-hdfs-datanode}.each do |pkg|
    it { expect(chef_run).to install_package(pkg) }
  end
end
