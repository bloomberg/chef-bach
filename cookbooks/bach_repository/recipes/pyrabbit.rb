#
# Cookbook Name:: bach_repository
# Recipe:: pyrabbit
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

directory "#{bins_dir}/python" do
  mode 0555
end

remote_file "#{bins_dir}/python/pyrabbit-1.0.1.tar.gz" do
  source 'http://pypi.python.org/packages/source/p/pyrabbit/pyrabbit-1.0.1.tar.gz'
  mode 0444
  checksum '7bc2b89fb332f62f4aaa891b1a4c8bfa38b32d154d44403afc83f00755528bdc'
end
