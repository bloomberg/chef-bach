#!/bin/bash

# Parameters:
# $1 is the vagrant install mode or user name to SSH as (see "Usage:" below)
# $2 is the IP address of the bootstrap node
# $3 is the optional knife recipe name, default "Test-Laptop"

set -e

if [[ $# -gt 1 ]]; then
  KEYFILE="bootstrap_chef.id_rsa"
  IP="$2"
  BCPC_DIR="chef-bcpc"
  VAGRANT=""
  # override the ssh-user and keyfile if using Vagrant
  if [[ $1 == "--vagrant-local" ]]; then
    echo "Running on the local Vagrant VM"
    VAGRANT="true"
    BCPC_DIR="~vagrant/chef-bcpc"
    SSH_USER="$USER"
    SSH_CMD="bash -c"
  elif [[ $1 == "--vagrant-remote" ]]; then
    echo "SSHing to the Vagrant VM"
    VAGRANT="true"
    BCPC_DIR="~vagrant/chef-bcpc"
    SSH_USER="vagrant"
    SSH_CMD="vagrant ssh -c"
  else
    SSH_USER="$1"
    SSH_CMD="ssh -t -i $KEYFILE ${SSH_USER}@${IP}" 
    echo "SSHing to the non-Vagrant machine ${IP} as ${SSH_USER}"
  fi
  if [[ $# -ge 3 ]]; then
      CHEF_ENVIRONMENT="$3"
  else
      CHEF_ENVIRONMENT="Test-Laptop"
  fi
  echo "Chef environment: ${CHEF_ENVIRONMENT}"
else
  echo "Usage: `basename $0` --vagrant-local|--vagrant-remote|<user name> IP-Address [chef environment]" >> /dev/stderr
  exit
fi

DIR=`dirname $0`
pushd $DIR

# protect against rsyncing to the wrong bootstrap node
if [[ ! -f "environments/${CHEF_ENVIRONMENT}.json" ]]; then
    echo "Error: environment file ${CHEF_ENVIRONMENT}.json not found"
    exit
fi

#
# Clear stale cookbooks in case we are re-running the
# tests/automated_install.sh script.
#
# This isn't entirely safe, but this script already assumes it can use
# rsync to overwrite anything in the vendor directory. Realistically,
# it should only be run on VM clusters.
#
$SSH_CMD "sudo chown -R vagrant $BCPC_DIR; \
	  sudo rm -rf /var/chef/cache/cookbooks; \
          sudo rm -rf $BCPC_DIR/vendor/cookbooks"

# Copy cluster mutable data to bootstrap.
if [[ -d ../cluster ]]; then
  # pull back the modified environment so that it can be copied to remote host
  tar -czf cluster.tgz ../cluster
  tar -C .. -cf - cluster | vagrant ssh -c 'cd ~; tar -xvf -'
elif [[ -f ./cluster.tgz ]]; then
  gunzip -c cluster.tgz | vagrant ssh -c 'cd ~; tar -xvf -'
else
  ( echo "############## No cluster data found in ../cluster or ./cluster.tgz! ##############" && exit 1 )
fi

echo "Running rsync of Vagrant install"
$SSH_CMD "rsync $RSYNCEXTRA -avP --exclude vbox --exclude vendor --exclude Gemfile.lock --exclude .kitchen --exclude .chef /chef-bcpc-host/ /home/vagrant/chef-bcpc/"

# cluster external environment will go here
#$SSH_CMD "mkdir -p cluster"
$SSH_CMD "tar -xzf /chef-bcpc-host/cluster.tgz -C /home/vagrant" || (echo '### Vagrant ssh failed to deploy cluster environment returned $? ###'; exit 1)
echo "Building bins"
$SSH_CMD "cd $BCPC_DIR && sudo ./build_bins.sh"
# https://github.com/bloomberg/chef-bach/issues/848
echo "HACK - removing stacktrace file, since the build_bins run succeeded."
$SSH_CMD "sudo rm -f /var/chef/cache/chef-stacktrace.out"
echo "Setting up chef server"
$SSH_CMD "cd $BCPC_DIR && sudo ./setup_chef_server.sh ${CHEF_ENVIRONMENT}"
echo "Setting up chef cookbooks"
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_cookbooks.sh ${IP} ${SSH_USER} ${CHEF_ENVIRONMENT}"
set -x
echo "Setting up chef environment, roles, and uploading cookbooks"
$SSH_CMD "cd $BCPC_DIR && sudo knife environment from file environments/${CHEF_ENVIRONMENT}.json -u admin -k /etc/chef-server/admin.pem"
$SSH_CMD "cd $BCPC_DIR && sudo knife role from file roles/*.json -u admin -k /etc/chef-server/admin.pem; r=\$? && sudo knife role from file roles/*.rb -u admin -k /etc/chef-server/admin.pem; r=\$((r & \$? )) && [[ \$r -lt 1 ]]"
$SSH_CMD "cd $BCPC_DIR && sudo knife cookbook upload -a -o vendor/cookbooks -u admin -k /etc/chef-server/admin.pem"

echo "Enrolling local bootstrap node into chef"
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_bootstrap_node.sh ${IP} ${CHEF_ENVIRONMENT}"

popd
