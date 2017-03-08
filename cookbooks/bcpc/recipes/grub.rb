# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# Cookbook Name:: bcpc
# Recipe:: grub.rb
#
# Copyright 2017, Bloomberg Finance L.P.
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
template '/etc/default/grub' do
  source 'grub/etc_default_grub.erb'
  owner 'root'
  group 'root'
  mode 0o0644
  notifies :run, 'execute[update-grub]'
end

execute 'update-grub' do
  command '/usr/sbin/update-grub'
  user 'root'
  action :nothing
end

template '/etc/init/ttyS0.conf' do
  source 'grub/ttyS0.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[initctl_reloadconfig]', :immediate
  notifies :restart, 'service[ttyS0]', :delayed
end

execute 'initctl_reloadconfig' do
  command '/sbin/initctl reload-configuration'
  action :nothing
end

service 'ttyS0' do
  supports status: true, restart: true, reload: false
  action [:start, :enable]
end
