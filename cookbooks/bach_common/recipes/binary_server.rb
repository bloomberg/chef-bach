#
# Cookbook Name:: bach_common
# Recipe:: binary_server
#
# BACH nodes are usually isolated from the internet, relying on the
# bootstrap host to serve binaries.  This recipe configures hosts to
# talk to a binary server instead of the internet.
#

binary_server_ip = node[:bcpc][:bootstrap][:server]
binary_server_url = "http://#{binary_server_ip}"

# We have to fix the gem sources before chef_gem runs.
directory '/opt/chef/embedded/etc' do
  user 'root'
  group 'root'
  mode 0755
end.run_action(:create)

file '/opt/chef/embedded/etc/gemrc' do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    # This file is maintained by Chef.
    # Local changes will be reverted.
    gem: --clear-sources --source http://10.0.101.2 --no-rdoc --no-ri
  EOM
end.run_action(:create)

ruby_block 'refresh_gemrc' do
  action :nothing
  block do
    Gem.configuration = Gem::ConfigFile.new([])
  end
end.run_action(:run)

apt_repository 'bach' do
  uri binary_server_url
  arch 'amd64'
  distribution '0.5.0'
  components ['main']
  key binary_server_url + '/apt_key.pub'
end

file '/etc/apt/apt.conf.d/00binary-server.conf' do
  mode 0444
  content <<-EOM.gsub(/^ {4}/,'')
    # This file is maintained by Chef.
    # Local changes will be reverted.
    Acquire::http::Proxy::#{binary_server_ip} 'DIRECT';
  EOM
end.run_action(:create)

