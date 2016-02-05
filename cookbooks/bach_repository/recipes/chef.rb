#
# Cookbook Name:: bach_repository
# Recipe:: chef
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
chef_path = "#{bins_dir}/chef_12.6.0-1_amd64.deb"
chef_url_path = "chef.deb"
client_download_url =
  "http://#{node[:bcpc][:bootstrap][:server]}/#{chef_url_path}"

remote_file chef_path do
  source 'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/10.04/x86_64/chef_12.6.0-1_amd64.deb'
  mode 0444
  checksum 'e0b42748daf55b5dab815a8ace1de06385db98e29a27ca916cb44f375ef65453'
  # For whatever reason, these S3 mirrors are not very reliable.
  retries 8
end

remote_file "#{bins_dir}/chef-server-core_12.1.2-1_amd64.deb" do
  source 'https://web-dl.packagecloud.io/chef/stable/packages/ubuntu/precise/chef-server-core_12.1.2-1_amd64.deb'
  mode 0444
  checksum '436c08c5b38705e19924a32f0885dd7f0f24a52c69a0259e93263dabf4b22ecb'
end

# This symlink is used by the URL in the bootstrap script.
link "#{bins_dir}/#{chef_url_path}" do
  to chef_path
end

template "#{bins_dir}/chef-install.sh" do
  source 'chef-install.sh.erb'
  mode 0555
  variables({ download_url: client_download_url })
end
