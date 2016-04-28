require 'pathname'
require 'rubygems'
gem_path = Pathname.new(Gem.ruby).dirname.join("gem").to_s

gem_package "rake-compiler" do
  gem_binary gem_path
  version ">=0.0.0"
  action :nothing
end.run_action(:install)

node['krb5']['devel']['packages'].each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

gem_package "rkerberos" do
  gem_binary gem_path
  version ">=0.0.0"
  action :nothing
end.run_action(:install)

execute "correct-gem-permissions" do
  command 'find /opt/chef/embedded/lib/ruby/gems -type f -exec chmod a+r {} \; && ' +
          'find /opt/chef/embedded/lib/ruby/gems -type d -exec chmod a+rx {} \;'
  user "root"
  action :nothing
end.run_action(:run)
