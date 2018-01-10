require 'simplecov'
require 'chefspec'
require 'chefspec/berkshelf'
require 'rspec/matchers'
require 'equivalent-xml'

formatters = [ SimpleCov::Formatter::HTMLFormatter ]

begin
  require 'simplecov-json'
  formatters.push(SimpleCov::Formatter::JSONFormatter)
rescue LoadError
end

begin
  require 'simplecov-rcov'
  formatters.push(SimpleCov::Formatter::RcovFormatter)
rescue LoadError
end

SimpleCov.formatters = formatters
SimpleCov.start

# Require all our libraries
Dir["#{__dir__}/../libraries/*.rb"].each do |f|
  begin
    require File.expand_path(f)
  rescue NameError => ex
    STDERR.write("Failed to load: #{ex}")
  end
end

RSpec.configure do |config|
  config.color = true
  config.alias_example_group_to :describe_recipe, type: :recipe

  Kernel.srand config.seed
  config.order = :random

  # run as though rspec --format documentation when passing a single spec file
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

end

Berkshelf.ui.mute do
  berksfile = Berkshelf::Berksfile.from_file('Berksfile')
  berksfile.vendor('../../vendor/cookbooks')
end

at_exit { ChefSpec::Coverage.report! }

# Helper function to set all the currently required attributes
# for the painful default attribute calculations we do
SET_ATTRIBUTES = Proc.new do |node|
  node.set['memory']['total'] = 1024
  node.set['cpu']['total'] = 1
  node.set[:bcpc] = {}
  # for bcpc/attributes/default.rb
  node.set[:lsb][:codename] = 'trusty'
  # for bcpc-hadoop/attributes/disks.rb
  node.set[:dmi][:system][:product_name] = 'Not VirtualBox'
  # for bcpc/attributes/default.rb
  node.set[:network][:default_interface] = 'eth0'
  node.set[:network][:interfaces][:eth0] = {'addresses' => {
      '08:00:27:1A:E9:1A' => {
        'family' => 'lladdr'
      },
      '10.0.2.15'   => {
        'family'    => 'inet',
        'prefixlen' => '24',
        'netmask'   => '255.255.255.0',
        'broadcast' => '10.0.2.255',
        'scope'     => 'Global'
      }
    }
  }
  # for bcpc-hadoop/attributes/disks.rb
  node.set[:block_device]
  # for bcpc-hadoop/attributes/hbase.rb
  node.set['bcpc']['floating']['ip'] = '0.0.0.0'
end

RSpec.shared_context 'recipe tests', type: :recipe do

  let(:chef_run) do
    ChefSpec::SoloRunner.new(node_attributes){ |n| SET_ATTRIBUTES.call(n) }\
      .converge(described_recipe)
  end

  def node_attributes
    {
      platform: 'ubuntu',
      version: '12.04',
    }
  end
end

