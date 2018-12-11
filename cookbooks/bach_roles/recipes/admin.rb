# "Role" recipe that is supposed to generate databags and supply them to the
# chef-server.  Mean to be run in an "admin" account on the chef-server.h
include_recipe 'bcpc::admin_repository_apt'
include_recipe 'bcpc::admin_certs'
include_recipe 'bcpc-hadoop::admin_ssl'
include_recipe 'bcpc::admin_cobbler'
include_recipe 'bach_krb5::admin'

if node.run_state[:kadmind_service].running
  include_recipe 'bcpc-hadoop::smoke_test_principal'
end

include_recipe 'bcpc::admin_ssh'
