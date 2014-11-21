#
# Cookbook Name:: bcpc
# Recipe:: bootstrap
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

include_recipe "bcpc::default"

node[:bcpc][:bootstrap][:admin_users].each do |user_name|
  user user_name do
    action :create
    home "/home/#{user_name}"
    group 'vagrant'
    supports :manage_home => true
  end
  bash 'set group permission on homedir' do
    code "chmod 775 /home/#{user_name}"
  end
end

sudo 'cluster-interaction' do
  user      node[:bcpc][:bootstrap][:admin_users] * ','
  runas     'vagrant'
  commands  ['/home/vagrant/chef-bcpc/cluster-assign-roles.sh','/home/vagrant/chef-bcpc/nodessh.sh','/usr/bin/knife']
  only_if { node[:bcpc][:bootstrap][:admin_users].length >= 1 }
end

bash 'create repo' do
  user 'vagrant'
  code 'git clone --bare /home/vagrant/chef-bcpc /home/vagrant/chef-bcpc-repo && cd /home/vagrant/chef-bcpc-repo && git config core.sharedRepository true'
  not_if { File.exists?('/home/vagrant/chef-bcpc-repo') }
end

bash 'set repo as origin' do
  user 'vagrant'
  cwd '/home/vagrant/chef-bcpc/'
  code 'git remote add local /home/vagrant/chef-bcpc-repo'
  not_if 'git remote -v |grep -q "^local	"', :cwd => '/home/vagrant/chef-bcpc/'
end

package 'acl'

bash 'Update chef-bcpc-repo rights' do
  code 'setfacl -R -m g:vagrant:rwX /home/vagrant/chef-bcpc-repo; find /home/vagrant/chef-bcpc-repo -type d | xargs setfacl -R -m d:g:vagrant:rwX'
end

cron 'synchronize chef' do
  user  'vagrant'
  home '/home/vagrant'
  command "cd ~/chef-bcpc; git pull local master; knife role from file roles/*.json; knife cookbook upload -a; knife environment from file environments/#{node.chef_environment}.json"
end

package 'sshpass'
