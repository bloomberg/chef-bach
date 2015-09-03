# -*- mode: ruby -*-
require 'highline'

ENV['BUILD_ID'] ||= '0'
ENV['CHEF_ENV'] ||= "Test-Laptop-b#{ENV['BUILD_ID']}"
ENV['CHEF_ENV_FILE'] = "environments/#{ENV['CHEF_ENV']}.json"

def chef_zero(recipe)
  puts "Chef environment: #{ENV['CHEF_ENV']}"
  config_path = File.dirname(__FILE__) + '/client.rb'
  command_line = 
    'bundle exec chef-client -z -l info' +
    " -c #{config_path}" +
    " -o bach_cluster::#{recipe}" +
    " -E #{ENV['CHEF_ENV']}"
  puts "Command line: #{command_line}"
  system(command_line) or
  fail "chef exited unsuccessfully"
end

def msg(string)
  puts HighLine.color(string, :yellow)
end

def base_path
  File.dirname(__FILE__)
end 

namespace :setup do
  desc 'Install all the prerequisites locally'
  task :prerequisites do
    # Vagrant 1.7.2 and below don't correctly handle >2 ethernet interfaces.
    vagrant_path = `which vagrant`.chomp
    vagrant_version = `vagrant --version`.chomp.gsub(/.*\s/,'')
    if(Gem::Version.new(vagrant_version) < Gem::Version.new('1.7.3'))
      raise HighLine.color("Vagrant 1.7.3 or greater is required, but " +
                           "#{vagrant_path} is #{vagrant_version} !",
                           :red)
    end

    ENV['BUNDLE_JOBS'] = `nproc`.chomp
    bundle_path = File.join(base_path, 'vendor', 'bundle')
    msg "Installing gems to #{bundle_path}"
    system "bundle install --quiet --path #{bundle_path}" or 
      raise "bundle exited unsuccessfully"
    cookbook_path = File.join(base_path, 'vendor', 'cookbooks')
    msg "Vendoring cookbooks to #{cookbook_path}"
    system "berks vendor --quiet #{cookbook_path}" or
      raise "berks exited unsuccessfully"
  end

  #
  # Unlike delivery-cluster, we use chef-zero to build our environment
  # JSON.  This allows us to use the helper methods in
  # bach_cluster/libraries to fill in IP addresses etc.
  #
  desc 'Generate the Chef environment file'
  task :environment, :node_count do |t, args|
    args.with_defaults(:node_count => 1)
    args = args.to_hash

    # Overwrite the old environment file with an empty JSON document.
    # (Chef expects to load the environment, but we don't have any data yet.)
    environment_json = 
      File.join(base_path, 'environments', "#{ENV['CHEF_ENV']}.json")
    File.truncate(environment_json,0) if File.exists?(environment_json)
    File.write(environment_json,"{}\n") or 
      fail "Failed to write empty environment to #{environment_json}!"

    # Copy rake arguments into the environment for use by chef.
    #
    # Rake arguments ("parameters") are terrible.  I gotta replace
    # this with a ./configure-type task.
    #
    args.keys.each do |key|
      ENV["BACH_CLUSTER_#{key.upcase}"] ||= args[key].to_s
    end

    chef_zero 'setup_environment'
  end

  desc 'Provision a bootstrap VM'
  task :bootstrap_vm do
    chef_zero 'setup_bootstrap_vm'
  end

  desc 'Provision a demo chef client'
  task :demo_vm do
    chef_zero 'setup_demo_vm'
  end
end

namespace :destroy do
  task :bootstrap_vm do
    chef_zero 'destroy_bootstrap_vm'
  end

  task :demo_vm do
    chef_zero 'destroy_demo_vm'
  end
end
