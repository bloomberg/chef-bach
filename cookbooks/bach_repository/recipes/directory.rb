#
# Cookbook Name:: bach_repository
# Recipe:: directory
#
# This (trivial) recipe is in a separate file so we can pluck recipes
# out of bach_repository at will.
#
bins_dir = node['bach']['repository']['bins_directory']
src_dir = node['bach']['repository']['src_directory']

directory bins_dir do
  user 'root'
  group 'root'
  mode 0755
  recursive true
end

directory src_dir do
  user 'root'
  group 'root'
  mode 0755
  recursive true
end
