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
sudo chown $(whoami):root /etc/chef/client.pem
sudo chmod 550 /etc/chef/client.pem
# It looks like knife fetch fails if the .chef directory is a symlink
# One gets:
# ERROR: Errno::EEXIST: File exists @ dir_s_mkdir - /home/vagrant/.chef
[ ! -L $(pwd)/.chef/$(hostname -f).pem ] && \
  sudo ln -s /etc/chef/client.pem $(pwd)/.chef/$(hostname -f).pem
[ ! -L /home/vagrant/.chef/knife.rb ] && \
  sudo ln -s $(pwd)/.chef/knife.rb /home/vagrant/.chef/knife.rb

# Knife explodes for root if knife.rb is missing for root
sudo mkdir -p /root/.chef
sudo chmod -R 700 /root/.chef
[ ! sudo test -L /root/.chef/$(hostname -f).pem ] && \
  sudo ln -s /etc/chef/client.pem /root/.chef/$(hostname -f).pem
[ ! sudo test -L /root/.chef/knife.rb ] && \
  sudo ln -s $(pwd)/.chef/knife.rb /root/.chef/knife.rb

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
     -o 'recipe[bcpc::bach_repository_wrapper],recipe[bach_repository::apt]'



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
