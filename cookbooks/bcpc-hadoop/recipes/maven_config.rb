require 'pathname'

node.override['maven']['install_java'] = false

internet_download_url = node['maven']['3']['url']
maven_file = Pathname.new(node['maven']['3']['url']).basename

node.override['maven']['3']['url'] = "#{get_binary_server_url}/#{maven_file}"

# download Maven only if not already stashed in the bins directory
remote_file "/home/vagrant/chef-bcpc/bins/#{maven_file}" do
  source internet_download_url
  action :create_if_missing
  mode '0555'
end
