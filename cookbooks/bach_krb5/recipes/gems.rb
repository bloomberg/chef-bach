require 'shellwords'

chef_gem 'rake-compiler' do
  options "--clear-sources -s #{get_binary_server_url}"
  compile_time true
end

node['krb5']['devel']['packages'].each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

chef_gem 'rkerberos' do
  options "--clear-sources -s #{get_binary_server_url}"
  compile_time true
end

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
