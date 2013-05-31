#!/bin/bash

set -e

if [[ $# -eq 2 ]]; then
  KEYFILE="bootstrap_chef.id_rsa"
  SSH_USER="$1"
  IP="$2"
  BCPC_DIR="chef-bcpc"
  VAGRANT=""
  SSH_CMD="ssh -t -i $KEYFILE ${SSH_USER}@${IP}" 
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
    echo "SSHing to the non-Vagrant machine ${IP}"
  fi
else
  echo "Usage: `basename $0` --vagrant-local|--vagrant-remote|<user name> IP-Address" >> /dev/stderr
  exit
fi


if [[ -z $VAGRANT ]]; then
  if [[ ! -f $KEYFILE ]]; then
    ssh-keygen -N "" -f $KEYFILE
  fi
  echo "Running rsync of non-Vagrant install"
  rsync -avP -e "ssh -i $KEYFILE" --exclude vbox --exclude $KEYFILE . ${SSH_USER}@$IP:chef-bcpc
  $SSH_CMD "cd $BCPC_DIR && ./setup_ssh_keys.sh ${KEYFILE}.pub"
else
  echo "Running rsync of Vagrant install"
  /usr/bin/rsync -avP --exclude vbox /chef-bcpc-host/ /home/vagrant/chef-bcpc/
fi

echo "Setting up chef server"
$SSH_CMD "cd $BCPC_DIR && sudo ./setup_chef_server.sh"
echo "Setting up chef cookbooks"
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_cookbooks.sh ${IP}"
echo "Setting up chef environment, roles, and uploading cookbooks"
$SSH_CMD "cd $BCPC_DIR && knife environment from file environments/*.json && knife role from file roles/*.json && knife cookbook upload -a -o cookbooks"
echo "Enrolling local bootstrap node into chef"
$SSH_CMD "cd $BCPC_DIR && ./setup_chef_bootstrap_node.sh ${IP}"
