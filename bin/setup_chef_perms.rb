#!/usr/bin/env ruby
require 'rubygems'
require 'chef/knife'
require 'chef/rest'

Chef::Config.from_file(ENV['HOME'], '.chef', 'knife.rb'))
options = {
  client_name: 'admin',
  raw_key: File.open('/etc/chef-server/admin.pem').read
}

rest = Chef::ServerAPI.new(Chef::Config[:chef_server_url], options)

Chef::Node.list.each do |node|
  %w{read update delete grant}.each do |perm|
    ace = rest.get("nodes/#{node[0]}/_acl")[perm]
    ace['actors'] << node[0] unless ace['actors'].include?(node[0])
    rest.put("nodes/#{node[0]}/_acl/#{perm}", perm => ace)
    puts "Client \"#{node[0]}\" granted \"#{perm}\" access on node \"#{node[0]}\""
  end
end
