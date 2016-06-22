#
# Cookbook Name:: bcpc
# Recipe:: mysql_client
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

apt_repository 'percona' do
  uri node['bcpc']['repos']['mysql']
  distribution node['lsb']['codename']
  components ['main']
  key 'percona-release.key'
end

#
# The modern percona packages require us to use the percona client.
#
# This should be source-compatible with standard MySQL clients, since
# it uses the same sonames.
#
package 'libperconaserverclient18-dev' do
  action :upgrade
end

#
# For Chef 11.x compatibility, it is important to use gem_package
# instead of chef_gem.  Chef 11 does not include the 'compile_time'
# attribute for chef_gem resources.
#
# Additionally, the Chef 11.x gem_package resource will fail to
# install unless a version is provided.  (I believe this is a bug.)
#
# As a result, these hardcoded versions will need to match the
# hardcoded versions found in build_bins.sh
#
{
  mysql2: '0.4.4',
  sequel: '4.36.0'
}.each do |gem_name, gem_version|
  gem_package gem_name.to_s do
    gem_binary File.join(Chef::Config.embedded_dir,'bin','gem')
    version gem_version
  end
end
