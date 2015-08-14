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

file "correct-permissions-for-rkerberos" do
  path "/opt/chef/embedded/lib/ruby/gems/1.9.1/specifications/rkerberos-0.1.3.gemspec"
  mode 0644
  action :nothing
end.run_action(:touch)

file "correct-permissions-for-rake-compiler" do
  path "/opt/chef/embedded/lib/ruby/gems/1.9.1/specifications/rake-compiler-0.9.5.gemspec"
  mode 0644 
  action :nothing
end.run_action(:touch)
