#
# Recipe to set graphite related attributes for graphite_handler and
# invoke the default recipe from graphite_handler
#
# This recipe should be the first recipe in the run list for all the
# nodes to collect chef-client stats and store into Graphite
#
node.default['chef_client']['handler']['graphite'].tap do |graphite|
  graphite['host'] = node['bcpc']['management']['vip']
  graphite['port'] = node['bcpc']['graphite']['relay_port']
  graphite['prefix'] = "chef.#{node['hostname']}"
end

#
# Pre-emptively install the correct gem with 'compile_time true'
# (It was this or chef-rewind.)
#
chef_gem 'simple-graphite' do
  options "--clear-sources --source #{get_binary_server_url}"
  version '>=2.1'
  compile_time true if respond_to?(:compile_time)
end

include_recipe 'graphite_handler::default'

#
# By default chef installs gemspec files with permission 770 on
# bootstrap node
#
# Need to change it so that all the users can read it without which
# scripts like nodessh will fail
#
Gem.path.each do |dir|
  Dir[Pathname.new(dir).join('specifications','simple-graphite*')].each do |val|
    file "#{val}" do
      action :create
      mode "0644"
    end
  end
end
