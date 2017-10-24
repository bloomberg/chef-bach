require 'serverspec'
require 'json'
require 'rubygems/dependency_installer'
Gem::DependencyInstaller.new.install('chef')
require 'chef/node'

set :backend, :exec

@node = \
  Chef::Node.from_hash(JSON.parse(IO.read('/tmp/kitchen/chef_node.json')))
