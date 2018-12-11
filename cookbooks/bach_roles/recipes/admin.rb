# "Role" recipe that is supposed to generate databags and supply them to the
# chef-server.  Mean to be run in an "admin" account on the chef-server.h
include_recipe 'bcpc::admin_repositorhy_apt'
include_recipe 'bcpc::admin_certs'
include_recipe 'bcpc-hadoop::admin_ssl'
include_recipe 'bcpc::admin_cobbler'
include_recipe 'bach_krb5::admin'

if node.run_state[:kadmind_service].running
  include_recipe 'bcpc-hadoop::smoke_test_principal'
end

# c-a-r basic related credentials
include_recipe 'bcpc::admin_ssh'

# c-a-r bootstrap related credentials
include_recipe 'bcpc::mysql_data_bags'
include_recipe 'bcpc::admin'
