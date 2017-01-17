#
# Cookbook Name:: kafka-bcpc
# Recipe:: default
#
# Kafka-bcpc is essentially a role cookbook. It sets a few attributes
# and includes other recipes.
#
# The 'default' recipe includes the common material shared between
# Zookeeper and Kafka servers in a standalone Kafka cluster.
#

include_recipe 'bcpc::chef_vault_install'
include_recipe 'bcpc::default'
include_recipe 'bcpc::networking'
include_recipe 'bcpc-hadoop::disks'
include_recipe 'bcpc::ubuntu_tools_repo'
include_recipe 'bcpc-hadoop::default'

# ensure we use /etc/security/limits.d to allow ulimit over-riding
if not node.has_key?('pam_d') or not node['pam_d'].has_key?('services') or not node['pam_d']['services'].has_key?('common-session')
  node.default['pam_d']['services'] = {
    'common-session' => {
      'main' => {
        'pam_permit_default' => {
          'interface' => 'session', 'control_flag' => '[default=1]', 'name' => 'pam_permit.so' },
        'pam_deny' => {
          'interface' => 'session', 'control_flag' => 'requisite', 'name' => 'pam_deny.so' },
        'pam_permit_required' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_permit.so' },
        'pam_limits' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_limits.so' },
        'pam_umask' => {
          'interface' => 'session', 'control_flag' => 'optional', 'name' => 'pam_umask.so' },
        'pam_unix' => {
          'interface' => 'session', 'control_flag' => 'required', 'name' => 'pam_unix.so' }
      },
      'includes' => []
    }
  }
end

# set vm.swapiness to 0 (to lessen swapping)
include_recipe 'sysctl::default'
sysctl_param 'vm.swappiness' do
  value 0
end
