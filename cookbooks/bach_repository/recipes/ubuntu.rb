#
# Cookbook Name:: bach_repository
# Recipe:: ubuntu
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/ubuntu-12.04-mini.iso" do
  source 'http://archive.ubuntu.com/ubuntu/dists/precise-updates/main/installer-amd64/20101020ubuntu136.21/images/netboot/mini.iso'
  mode 0444
  checksum '6150143c06369134c15ac771a3b349a18c7d4660c1755b8fbefc032269a74f8f'
end
