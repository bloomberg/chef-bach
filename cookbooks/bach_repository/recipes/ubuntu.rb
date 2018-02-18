#
# Cookbook Name:: bach_repository
# Recipe:: ubuntu
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

remote_file "#{bins_dir}/ubuntu-14.04-hwe44-mini.iso" do
  source 'http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/' +
         'installer-amd64/current/images/xenial-netboot/mini.iso'
  mode 0444
  checksum '28b11928cd8bd63ee522f2e9b0a2f3bfd0dd1d826471e8f7726d65d583b32154'
end

