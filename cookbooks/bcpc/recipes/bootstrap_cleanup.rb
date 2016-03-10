ruby_block "cleanup-old-environment-databag" do
  block do
    rest = Chef::REST.new(node[:bcpc][:bootstrap][:server], "admin", "/etc/chef-server/admin.pem")
    rest.delete("/environments/GENERIC")
    rest.delete("/data/configs/GENERIC")
  end
  action :create
  ignore_failure true
end

ruby_block "cleanup-old-clients" do
  block do
    system_clients = ["chef-validator", "chef-webui"]
    rest = Chef::REST.new(node[:bcpc][:bootstrap][:server], "admin", "/etc/chef-server/admin.pem")
    rest.get_rest("/clients").each do |client|
      if !system_clients.include?(client.first)
        rest.delete("/clients/#{client.first}")
      end
    end
  end
  action :create
  ignore_failure true
end

ruby_block "cleanup-old-nodes" do
  block do
    rest = Chef::REST.new(node[:bcpc][:bootstrap][:server], "admin", "/etc/chef-server/admin.pem")
    rest.get_rest("/nodes").each do |n|
        rest.delete("/nodes/#{n.first}")      
    end
  end
  action :create
  ignore_failure true
end

Dir["/home/vagrant/chef-bcpc/.chef/*.pem"].each do |f|
  file "#{f}" do
    action :delete
  end
end

file "/home/vagrant/chef-bcpc/environments/GENERIC.json" do
  action :delete
end
