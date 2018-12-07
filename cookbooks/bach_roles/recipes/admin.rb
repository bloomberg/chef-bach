# "Role" recipe that is supposed to generate databags and supply them to the
# chef-server.  Mean to be run in an "admin" account on the chef-server.h
include_recipe 'bcpc::admin_repository_apt'
include_recipe 'bach_krb5::admin'
include_recipe 'bcpc::admin_certs'
include_recipe 'bcpc-hadoop::admin_ssl'
