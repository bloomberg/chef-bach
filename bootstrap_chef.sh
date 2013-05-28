#!/bin/bash

set -e

if [[ $# -eq 2 ]]; then
  KEYFILE="bootstrap_chef.id_rsa"
  SSH_CMD="$SSH_CMD"
  SSH_USER="$1"
  BCPC_DIR="chef-bcpc"
  VAGRANT=""
  # override the ssh-user and keyfile if using Vagrant
  if [[ $1 == "--vagrant-local" ]]; then
    echo "Running on the local Vagrant VM"
    VAGRANT="true"
    BCPC_DIR="~vagrant/chef-bcpc"
    SSH_CMD="bash -c"
  elif [[ $1 == "--vagrant-remote" ]]; then
    echo "SSHing to the Vagrant VM"
    VAGRANT="true"
    BCPC_DIR="~vagrant/chef-bcpc"
    SSH_CMD="vagrant ssh -c"
  else
    echo "SSHing to the non-Vagrant machine $2"
  fi
  IP="$2"
else
  echo "Usage: `basename $0` --vagrant-local|--vagrant-remote|<user name> IP-Address" >> /dev/stderr
  exit
fi


if [[ -z $VAGRANT ]]; then
  if [[ ! -f $KEYFILE ]]; then
    ssh-keygen -N "" -f $KEYFILE
  fi
  rsync -avP -e "ssh -i $KEYFILE" --exclude vbox --exclude $KEYFILE . ${SSH_USER}@$IP:chef-bcpc
  ssh -i $KEYFILE ${SSH_USER}@$IP "cd $BCPC_DIR && ./setup_ssh_keys.sh $KEYFILE.pub"
else
  /usr/bin/rsync -avP --exclude '*.iso' --exclude '*.img' --exclude '*.box' --exclude '*.rom' /chef-bcpc-host/ ~vagrant/chef-bcpc/
fi

$SSH_CMD "cd $BCPC_DIR && sudo ./setup_chef_server.sh"
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_cookbooks.sh"
$SSH_CMD "cd $BCPC_DIR && knife environment from file environments/*.json && knife role from file roles/*.json && knife cookbook upload -a -o cookbooks"
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_bootstrap_node.sh ${IP}"
