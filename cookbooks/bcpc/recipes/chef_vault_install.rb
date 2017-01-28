#
# Cookbook Name:: bcpc
# Recipe:: chef vault install
#
# Copyright 2015, Bloomberg Finance L.P.
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

require 'pathname'
require 'rubygems'
require 'uri'

gem_path = Pathname.new(Gem.ruby).dirname.join('gem').to_s

chefvault_version = '>=2.8.0'

#
# Move to installing chef-vault via execute block to work around
# issue where version string is empty when combining gem_binary,
# version and options in the gem_package resource
#
execute 'gem_install_chef-vault' do
  command gem_path + ' install chef-vault -q --no-rdoc --no-ri -v "' \
    + chefvault_version + "\" --clear-sources -s #{get_binary_server_url}"
  not_if gem_path + ' list chef-vault -i -v "' + chefvault_version + '"'
  action :nothing
  environment ({ 'no_proxy' => URI.parse(get_binary_server_url).host })
end.run_action(:run)

#
# BACH typically runs chef-client with an abnormal umask, which causes
# rubygems to install specifications with bad permissions.
#
# This ruby block restores the permissions to root/root, rw-r--r--
#
ruby_block 'fix-chef-gemspec-permissions' do
  block do
    Dir.glob(Gem.default_dir + '/specifications/*.gemspec').each do |path|
      File.chown(0, 0, path)
      File.chmod(0644, path)
    end
  end
end.run_action(:create)

Gem.clear_paths
