# -*- mode: enh-ruby -*-
source 'https://rubygems.org'
ruby RUBY_VERSION

gem 'chef-vault', '>= 2.6.1'
gem 'faker'
gem 'ipaddress'
gem 'highline'
gem 'mixlib-shellout'
gem 'parallel'
gem 'pry'
gem 'ruby-progressbar'

gem 'rack', '1.6.4'
gem 'chef', '12.2.1'
gem 'buff-ruby_engine', '0.1.0'
gem 'buff-extensions', '1.0.0'
gem 'fauxhai', '3.6.0'

Dir.glob(File.join(File.dirname(__FILE__), 'cookbooks', '**', "Gemfile")) do |gemfile|
    eval(IO.read(gemfile), binding)
end

