require 'rubygems'
require 'chef/knife'
require 'chef/server_api'

knife_rb_path = File.join(ENV['HOME'], 'chef-bcpc', '.chef', 'knife.rb')
config = File.open(knife_rb_path).read
config.gsub!(/^client_key .*$/, "client_key '/etc/chef-server/admin.pem'")
config.gsub!(/^node_name .*$/, "node_name 'admin'")

#Chef::Config.from_file(knife_rb_path)
Chef::Config.from_string(config, 'Modified knife.rb')

options = {
  client_name: 'admin',
  raw_key: File.open('/etc/chef-server/admin.pem').read
}

rest = Chef::ServerAPI.new(Chef::Config[:chef_server_url])

Chef::Node.list.each do |node|
  %w{read update delete grant}.each do |perm|
    ace = rest.get("nodes/#{node[0]}/_acl")[perm]
    ace['actors'] << node[0] unless ace['actors'].include?(node[0])
    rest.put("nodes/#{node[0]}/_acl/#{perm}", perm => ace)
    puts "Client \"#{node[0]}\" granted \"#{perm}\" access on node \"#{node[0]}\""
  end
end
