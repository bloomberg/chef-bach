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

%w{make gcc pkg-config libaugeas-dev}.each do |pkg|
  package pkg do
    action :nothing
  end.run_action(:install)
end

require 'pathname'
require 'rubygems'
gem_path = Pathname.new(Gem.ruby).dirname.join('gem').to_s

gem_package 'ruby-augeas' do
    gem_binary gem_path
    version ">=0.0.0"
    action :nothing
end.run_action(:install)

#
# With a restrictive umask chef installs gemspec files with permission 770 on bootstrap node 
# Need to change it so that all the users can read it without which knife without sudo will fail
#
Gem.path.each do |dir|
  Dir[Pathname.new(dir).join("specifications","ruby-augeas*")].each do |val|
    file "#{val}" do
      action :create
      mode "0644"
    end
  end
end

Gem.clear_paths
require 'augeas'

include_recipe "bcpc::default"

if node[:bcpc][:networks].length > 1
  include_recipe "bfd::default"
  bfd_session "Global Bootstrap VIP Connect" do
    action :connect
    remote_ip node[:bcpc][:networks][node[:bcpc][:management][:subnet]][:management][:gateway]
    local_ip node[:bcpc][:management][:ip]
  end
  Augeas::open do |aug|
    aug.set("/augeas/load/Interfaces/incl", "/etc/network/interfaces.d/*")
    aug.load
    # Check if an interface file defines the VIP address already -- ifconfig seems a bit loose in its checks
    if aug.match("/files/etc/network/interfaces.d/*/iface/address[. = '#{node[:bcpc][:bootstrap][:vip]}']").length == 0
      ifconfig node[:bcpc][:bootstrap][:vip] do
        device "#{node[:bcpc][:bootstrap][:pxe_interface]}:0"
        mask "255.255.255.255"
        action [:add]
      end
    end
  end
  ifs = node[:network][:interfaces].keys
  # create a hash of ipaddresses -- skip interfaces without addresses
  ips = ifs.map{ |a| node[:network][:interfaces][a].attribute?(:addresses) and
                     node[:network][:interfaces][a][:addresses] or {}}.reduce({}, :merge)
  if not ips.keys.include?(node[:bcpc][:bootstrap][:vip]) 
    ifconfig node[:bcpc][:bootstrap][:vip] do
      device "#{node[:bcpc][:bootstrap][:pxe_interface]}:0"
      mask "255.255.255.255"
      action [:enable]
    end
  end
  bfd_session "Global Bootstrap VIP Up" do
    action :up
    remote_ip node[:bcpc][:networks][node[:bcpc][:management][:subnet]][:management][:gateway]
    local_ip node[:bcpc][:management][:ip]
  end
end

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

link '/etc/chef/client.d/knife.rb' do
  to '/home/vagrant/chef-bcpc/.chef/knife.rb'
end
