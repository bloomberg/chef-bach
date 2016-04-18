require 'simplecov'
require 'chefspec'
require 'chefspec/berkshelf'

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
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

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

berks = Berkshelf::Berksfile.from_file('Berksfile').install()

at_exit { ChefSpec::Coverage.report! }

RSpec.shared_context 'recipe tests', type: :recipe do

  let(:chef_run) { ChefSpec::SoloRunner.new(node_attributes).converge(described_recipe) }

  def node_attributes
    {
      platform: 'ubuntu',
      version: '12.04',
    }
  end
end
