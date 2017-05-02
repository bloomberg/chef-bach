#
# Recipe to set graphite related attributes for graphite_handler and
# invoke the default recipe from graphite_handler
#
# This recipe should be the first recipe in the run list for all the
# nodes to collect chef-client stats and store into Graphite
#
simple_graphite_version = '>=2.1'

node.default['chef_client']['handler']['graphite'].tap do |graphite|
  graphite['host'] = node['bcpc']['management']['vip']
  graphite['port'] = node['bcpc']['graphite']['relay_port']
  graphite['prefix'] = "chef.#{node['hostname']}"
end

node.default['chef_client']['handler']['gem'].tap do |gem|
  gem['location'] = get_binary_server_url
  gem['version'] = simple_graphite_version
end

# Pre-emptively install the correct gem with 'compile_time true'
bcpc_chef_gem 'simple-graphite' do
  version simple_graphite_version
  compile_time true
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
