require 'pathname'

node.override['maven']['install_java'] = false

internet_download_url = node['maven']['url']
maven_file = Pathname.new(node['maven']['url']).basename

node.override['maven']['url'] = "#{get_binary_server_url}/#{maven_file}"

# download Maven only if not already stashed in the bins directory
remote_file "/home/vagrant/chef-bcpc/bins/#{maven_file}" do
  source internet_download_url
  action :create
  mode 0555
  checksum node['maven']['checksum']
end

# Setup custom maven config
directory '/root/.m2' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template "maven_settings.xml" do
  path '/root/.m2/settings.xml'
  source 'maven_settings.xml.erb'
  owner 'root' 
  group 'root'
  mode '0644'
end
