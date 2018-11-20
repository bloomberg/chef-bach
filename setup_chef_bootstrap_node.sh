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

sudo knife clean create $(hostname -f) -a -d -f .chef/$(hostname -f).pem \
  -u admin -k /etc/chef-server/admin.pem
PEM_RELATIVE_PATH=.chef/$(hostname -f).pem
sudo chown $(whoami):root $PEM_RELATIVE_PATH
sudo chmod 550 $PEM_RELATIVE_PATH

# Assume we are running in the chef-bcpc directory
sudo /opt/chefdk/bin/chef-client -E "$CHEF_ENVIRONMENT" -c .chef/knife.rb
[ ! -L /etc/chef/client.pem ] && \
  sudo ln -s $(readlink -f $PEM_RELATIVE_PATH) /etc/chef/client.pem
[ ! -L ~/.chef ] && \
  sudo ln -s $(readlink -f .chef) ~/.chef

echo "Setting up chef environment, roles, and uploading cookbooks"
knife environment from file environments/${CHEF_ENVIRONMENT}.json
knife role from file roles/*.json
knife cookbook upload -a

#
# build_bins.sh has already built the BCPC local repository, but we
# still need to configure Apache and chef-vault before doing a
# complete Chef run.
#
sudo -E /opt/chefdk/bin/chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bcpc::apache-mirror]'

sudo -E /opt/chefdk/bin/chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bcpc::chef_vault_install]'

sudo /opt/chefdk/bin/chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bcpc::chef_poise_install]'


#
# For some reason that I don't understand,we need to do this before
# BCPC-Bootstrap so that we have os in the chef vault to allow bootstrap-gpg
# to be properly put inside the configs/Test-Laptop data bag as we aren't even installing the chef vault until after the first apt run
#
sudo -E /opt/chefdk/bin/chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bach_repository::apt]'



#
# With chef-vault installed and the repo configured, it's safe to save
# and converge the complete runlist.
#
sudo -E /opt/chefdk/bin/chef-client \
     -c .chef/knife.rb \
     -r 'role[BCPC-Bootstrap]'

#
# TODO: This chef run should not be necessary.  This is definitely a
# bug in the bach_repository::apt recipe.  The bootstrap fails to save
# its GPG public/private keys even after it should be able to do so.
#
sudo -E /opt/chefdk/bin/chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bach_repository::apt]'
