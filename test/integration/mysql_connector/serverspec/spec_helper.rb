require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'serverspec'
ENV['GEM_PATH']=::Dir.glob('/opt/chef/embedded/lib/ruby/gems/*').join(':')
Gem.clear_paths
require 'ohai'

# Required by serverspec
set :backend, :exec

RSpec.configure do |c|
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end
end
