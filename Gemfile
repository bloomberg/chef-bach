# -*- mode: enh-ruby -*-
ruby RUBY_VERSION
source 'https://rubygems.org' do

  gem 'chef-vault', '2.9.0' # same as the cluster uses
  gem 'faker'
  gem 'ipaddress'
  gem 'highline'
  gem 'mixlib-shellout'
  gem 'parallel'
  gem 'poise'

  # We rely on chef-provisioning to monitor hosts on SSH.
  gem 'chef-provisioning', '1.2.1'
  gem 'chef-provisioning-ssh'

  # These versions are pinned to match ChefDK 0.12.0
  gem 'rack', '1.6.4'
  gem 'buff-extensions', '1.0.0'
  gem 'buff-ruby_engine', '0.1.0'
  gem 'chef', '12.2.1'
  gem 'fauxhai', '3.1.0'
  gem 'nio4r', '1.2.1'

  gem 'json'
  gem 'ridley', '4.5.0'
  gem 'pry'
  gem 'ruby-progressbar'
end

Dir.glob(File.join(File.dirname(__FILE__), 'cookbooks', '**', "Gemfile")) do |gemfile|
    eval(IO.read(gemfile), binding)
end
