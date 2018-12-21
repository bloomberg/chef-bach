#!/bin/bash

# Parameters :
# $1 is the IP address of the bootstrap node
# $2 is the Chef environment name, default "Test-Laptop"

set -e
set -x

if [[ $# -ne 2 ]]; then
	echo "Usage: `basename $0` IP-Address Chef-Environment" >> /dev/stderr
	exit
fi

CHEF_SERVER=$1
CHEF_ENVIRONMENT=$2

# Enough chef-client configuration in the bootstrap machine to converge.  Will
# be replaced by bcpc::chef_client after converge of role[BCPC-Bootstrap].
sudo knife configure client /etc/chef -c .chef/knife.rb  -y -u $(hostname -f)
sudo knife ssl fetch -c /etc/chef/client.rb
# FIXME: Remove after migrating to chef-server 12
# FIXME: Remove "-a" flag before migrating to chef-server 12
sudo knife client create $(hostname -f) -a -d -f /etc/chef/client.pem \
  -u admin --key /etc/chef-server/admin.pem
sudo /opt/chefdk/bin/chef-client -E "$CHEF_ENVIRONMENT"

# FIXME: bootstrap-admin chef-run needs to always be "-o" to prevent node
# attributes being populated.  In Chef 13 we can use attribute whitelists on
# knife.rb so that this is no longer needed.
chef-client -c .chef/knife.rb -E  "$CHEF_ENVIRONMENT" -o bach_roles::admin
# FIXME: Some chef-bach stuff still uses an actual node search and doesn't
# expect the bootstrap-admin node object to exists.
knife node delete -y bootstrap-admin

#
# build_bins.sh has already built the BCPC local repository, but we
# still need to configure Apache and chef-vault before doing a
# complete Chef run.
#
sudo -E /opt/chefdk/bin/chef-client \
     -o 'recipe[bcpc::apache-mirror]'

sudo -E /opt/chefdk/bin/chef-client \
     -o 'recipe[bcpc::chef_vault_install]'

sudo /opt/chefdk/bin/chef-client \
     -o 'recipe[bcpc::chef_poise_install]'


#
# For some reason that I don't understand,we need to do this before
# BCPC-Bootstrap so that we have os in the chef vault to allow bootstrap-gpg
# to be properly put inside the configs/Test-Laptop data bag as we aren't even installing the chef vault until after the first apt run
#
sudo -E /opt/chefdk/bin/chef-client \
     -o 'recipe[bach_repository::apt]'

#
# With chef-vault installed and the repo configured, it's safe to save
# and converge the complete runlist.
#
sudo -E /opt/chefdk/bin/chef-client \
     -r 'role[BCPC-Bootstrap]'

# Needed to be reconverged in order to generate keytabs in the bootstrap
# machine.  Not needed when using an external KDC
chef-client -c .chef/knife.rb -E  "$CHEF_ENVIRONMENT" -o bach_roles::admin
# FIXME: Some chef-bach stuff still uses an actual node search and doesn't
# expect the bootstrap-admin node object to exists.
knife node delete -y bootstrap-admin

#
# TODO: This chef run should not be necessary.  This is definitely a
# bug in the bach_repository::apt recipe.  The bootstrap fails to save
# its GPG public/private keys even after it should be able to do so.
#
sudo -E /opt/chefdk/bin/chef-client \
     -o 'recipe[bach_repository::apt]'
