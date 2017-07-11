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

# Assume we are running in the chef-bcpc directory
sudo chef-client -E "$CHEF_ENVIRONMENT" -c .chef/knife.rb
PEM_RELATIVE_PATH=.chef/$(hostname -f).pem
sudo chown $(whoami):root $PEM_RELATIVE_PATH
sudo chmod 550 $PEM_RELATIVE_PATH
sudo ln -s $(readlink -f $PEM_RELATIVE_PATH) /etc/chef/client.pem
sudo ln -s $(readlink -f .chef) ~/.chef

admin_val=`knife client show $(hostname -f) -c .chef/knife.rb | grep ^admin: | sed "s/admin:[^a-z]*//"`
if [[ "$admin_val" != "true" ]]; then
  # Make this client an admin user before proceeding.
  echo -e "/\"admin\": false\ns/false/true\nw\nq\n" | EDITOR=ed sudo -E knife client edit `hostname -f` -c .chef/knife.rb -k /etc/chef-server/admin.pem -u admin
fi

#
# build_bins.sh has already built the BCPC local repository, but we
# still need to configure Apache and chef-vault before doing a
# complete Chef run.
#
sudo -E chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bcpc::apache-mirror]'

sudo -E chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bcpc::chef_vault_install]'

sudo chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bcpc::chef_poise_install]'

#
# With chef-vault installed and the repo configured, it's safe to save
# and converge the complete runlist.
#
sudo -E chef-client \
     -c .chef/knife.rb \
     -r 'role[BCPC-Bootstrap]'

#
# TODO: This chef run should not be necessary.  This is definitely a
# bug in the bach_repository::apt recipe.  The bootstrap fails to save
# its GPG public/private keys even after it should be able to do so.
#
sudo -E chef-client \
     -c .chef/knife.rb \
     -o 'recipe[bach_repository::apt]'
