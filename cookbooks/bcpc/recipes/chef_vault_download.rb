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

target_filename = node['bcpc']['chefvault']['filename']
link_filename = "chef-vault.gem"
package_path = "#{node['bcpc']['bin_dir']['gems']}/#{target_filename}"
checksum = node['bcpc']['chefvault']['checksum']


if !File.exists?(package_path)

# download rubygem from website
  remote_file "#{ target_filename }" do
    source "#{ node['bcpc']['gem_source'] }/#{ target_filename }"
    checksum checksum
    group "root"
    owner "root"
    mode "755"
    path package_path
    action :nothing
  end.run_action(:create_if_missing)
  
  link "#{node['bcpc']['bin_dir']['gems']}/#{ link_filename }" do
    owner 'root'
    to "#{node['bcpc']['bin_dir']['gems']}/#{ target_filename }"
    action :nothing
  end.run_action(:create)
  
  bash 'build_bins' do
    action :nothing
    user 'root'
    cwd '/home/vagrant/chef-bcpc'
    code <<-EOH
      ./build_bins.sh
    EOH
    umask 0002
  end.run_action(:run)

end
