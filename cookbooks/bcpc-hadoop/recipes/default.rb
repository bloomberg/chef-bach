#
# Cookbook Name:: bcpc-hadoop
# Recipe:: default
#
# Copyright 2013, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# ensure the Zookeeper Gem is available for use in later recipes
# it seems chef_gem fails to use the embedded gem(1) binary so use gem_package
# and a hack to use rubygems to find the current Ruby binary;
# assume gem is in the same dir (valid for Chef 10, Chef 11 dpkg and Chef 11 Omnibus)
require 'pathname'
require 'rubygems'
gem_path = Pathname.new(Gem.ruby).dirname.join("gem").to_s

# build requirements for zookeeper
%w{ruby-dev make patch gcc}.each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

chef_gem 'poise' do
  version '~>2.0'
  options "--clear-sources -s #{get_binary_server_url}"
  compile_time true
end

chef_gem 'json' do
  # Due to Zabbixapi #64 otherwise could use 2.0+
  version '~>1.6'
  options "--clear-sources -s #{get_binary_server_url}"
  compile_time true
end

chef_gem 'zookeeper' do
  version '>0.0'
  options "--clear-sources -s #{get_binary_server_url}"
  compile_time true
end

chef_gem 'webhdfs' do
  options "--clear-sources -s #{get_binary_server_url}"
  version '>=0.0.0'
  compile_time true
end

chef_gem 'zabbixapi' do
  options "--clear-sources -s #{get_binary_server_url}"
  version '>=2.4'
  compile_time true
end

['libxslt1-dev', 'libxml2-dev', 'pkg-config'].each do |pkg_name|
  package pkg_name do
    action :upgrade
  end.run_action(:install)
end

#
# By default, nokogiri will attempt to install libxml2, libxslt, and
# zlib from the internet.
#
# The "--use-system-libraries" switch is intended to force nokogiri
# extconf.rb to compile against system libraries.
#
chef_gem 'nokogiri' do
  options "--clear-sources -s #{get_binary_server_url} " \
    '-- --use-system-libraries'
  version '>=1.6.2'
  compile_time true
end

Gem.clear_paths
require 'zookeeper'

execute "correct-gem-permissions" do
  command 'find /opt/chef/embedded/lib/ruby/gems -type f -exec chmod a+r {} \; && ' +
          'find /opt/chef/embedded/lib/ruby/gems -type d -exec chmod a+rx {} \;'
  user "root"
   action :nothing
end.run_action(:run)
