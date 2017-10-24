#
# Cookbook Name:: bach_repository
# Recipe:: permissions
#
# chef-bach uses a non-standard umask during chef runs.  Many, many
# tools fail to account for unexpected umasks, and bad permissions
# are written to disk.  This recipe exists to fix all permissions on
# the repo at once.
#
require 'pathname'

bins_dir = node['bach']['repository']['bins_directory']

Pathname.new(bins_dir).descend do |path|
  directory path.to_s do
    mode 0755
  end
end

execute "find '#{bins_dir}' -type d -exec chmod ugo+rx {} \\;"
execute "find '#{bins_dir}' -type f -exec chmod ugo+r {} \\;" 
