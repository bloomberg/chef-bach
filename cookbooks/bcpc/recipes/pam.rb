#
# Cookbook Name:: bcpc
# Recipe:: pam
#
# Copyright 2018, Bloomberg Finance L.P.
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

# Chef recipe to implement pam_namespace polyinstantiated directories
# This will provide users the appearance they are the only user with data
# in the affected directories -- also this will clean-up their data when
# leaving the machine

directory '/inst-dirs' do
  user 'root'
  group 'root'
  mode 0o000
end

directory '/usr/local/sbin' do
  action :create
end

polyinstantion_dir = node['bcpc']['pam_namespace']['polyinstantion_dir']
shm_polyinstantion_dir = node['bcpc']['pam_namespace']['shm_polyinstantion_dir']

template '/usr/local/sbin/inst_dir.sh' do
  source 'inst_dir.sh.erb'
  mode 500
  variables(shm_polyinstantion_dir: shm_polyinstantion_dir,
            polyinstantion_dir: polyinstantion_dir)
end

template '/etc/security/namespace.conf' do
  source 'pam_namespace.conf.erb'
  mode 500
  variables(lazy {{ real_home_dir_users:
                     node['bcpc']['pam_namespace']['real_home_dir_users'].uniq.sort.join(','),
                   shm_polyinstantion_dir: shm_polyinstantion_dir,
                   polyinstantion_dir: polyinstantion_dir
                 }})
end

template '/etc/security/namespace.init' do
  source 'pam_namespace.init.erb'
  mode 755
end

# NOTE: This include_recipe is necessary for resource collection
include_recipe 'sysctl::default'

# ensure we use /etc/security/limits.d to allow ulimit overriding
if !node.key?('pam_d') || !node['pam_d'].key?('services') || !node['pam_d']['services'].key?('common-session')
  node.default['pam_d']['services'] = {
    'common-session' => {
      'main' => {
        'pam_permit_default' =>  { 'interface' => 'session', 'control_flag' => '[default=1]', 'name' => 'pam_permit.so' },
        'pam_deny' =>            { 'interface' => 'session', 'control_flag' => 'requisite', 'name' => 'pam_deny.so' },
        'pam_permit_required' => { 'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_permit.so' },
        'pam_limits' =>          { 'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_limits.so' },
        'pam_umask' =>           { 'interface' => 'session', 'control_flag' => 'optional', 'name' => 'pam_umask.so' },
        'pam_unix' =>            { 'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_unix.so' },
        'pam_exec' =>            { 'interface' => 'session', 'control_flag' => 'optional', 'name' => 'pam_exec.so', 'args' => '/usr/local/sbin/inst_dir.sh' },
        'pam_namespace' =>       { 'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_namespace.so', 'args' => 'unmnt_remnt' },
      },
      'includes' => []
    }
  }
end

# set vm.swapiness to 0 (to lessen swapping)
sysctl_param 'vm.swappiness' do
  value 0
end

# Reboot on kernel panic
sysctl_param 'kernel.panic' do
  value 1800
end
