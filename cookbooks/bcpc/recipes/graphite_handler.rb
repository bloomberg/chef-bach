#
# Recipe to set graphite related attributes for graphite_handler and invoke the default recipe
# from graphite_handler
# This recipe should be the first recipe in the run list for all the nodes to collect chef-client
# stats and store into Graphite
#
node.default['chef_client']['handler']['graphite']['host'] = node['bcpc']['management']['vip']
node.default['chef_client']['handler']['graphite']['port'] = node['bcpc']['graphite']['relay_port']
node.default['chef_client']['handler']['graphite']['prefix'] = "chef.#{node['hostname']}"

# See bach_repository::gems for correct version.
node.set['chef_client']['handler']['gem']['version'] = '2.1.0'

log "Gem configuration: #{Gem.configuration.inspect}"

include_recipe 'graphite_handler::default'

#
# By default chef installs gemspec files with permission 770 on bootstrap node 
# Need to change it so that all the users can read it without which scripts like nodessh will fail
#
Gem.path.each do |dir|
  Dir[Pathname.new(dir).join("specifications","simple-graphite*")].each do |val|
    file "#{val}" do
      action :create
      mode "0644"
    end
  end
end
