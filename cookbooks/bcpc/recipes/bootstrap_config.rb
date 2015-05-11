file "/home/vagrant/chef-bcpc/.chef/#{node[:hostname]}.pem" do
  owner 'vagrant'
  group 'root'
  mode '550'
end

directory "/home/vagrant/chef-bcpc/.chef/syntax_check_cache" do
  owner 'vagrant'
  group 'root'
  mode '550'
  recursive true
  action :delete
end

ruby_block "convert-bootstrap-to-admin" do
  block do
    rest = Chef::REST.new(node[:bcpc][:bootstrap][:server], "admin", "/etc/chef-server/admin.pem")
    rest.put_rest("/clients/#{node[:hostname]}",{:admin => true})
    rest.put_rest("/nodes/#{node[:hostname]}", {:name => node[:hostname], :run_list => ['role[BCPC-Bootstrap]']})
  end
  action :create
end
