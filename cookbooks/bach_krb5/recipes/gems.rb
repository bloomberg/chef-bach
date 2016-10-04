require 'pathname'
require 'rubygems'
require 'shellwords'

gem_path = Pathname.new(Gem.ruby).dirname.join('gem').to_s

gem_package 'rake-compiler' do
  gem_binary gem_path
  version '>=0.0.0'
  action :nothing
end.run_action(:install)

node['krb5']['devel']['packages'].each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

gem_package 'rkerberos' do
  gem_binary gem_path
  version '>=0.0.0'
  action :nothing
end.run_action(:install)

#
# BACH typically runs chef-client with an abnormal umask, which causes
# rubygems to install files with bad permissions.
#
# This execute resource restores the gem permissions to a minimum of
# 755 on directories and 644 on ordinary files.
#
execute 'correct-chef-gem-permissions' do
  gem_dir = Shellwords.escape(Gem.dir)
  command "find #{gem_dir} -type f -exec chmod a+r {} \\; && " +
          "find #{gem_dir} -type d -exec chmod a+rx {} \\;"
  user 'root'
  action :nothing
end.run_action(:run)
