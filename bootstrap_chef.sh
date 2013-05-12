#!/bin/bash

set -e

KEYFILE=bootstrap_chef.id_rsa

if [ ! -f $KEYFILE ]; then
  ssh-keygen -N "" -f $KEYFILE
fi

rsync -avP -e "ssh -i $KEYFILE" --exclude vbox --exclude $KEYFILE . ubuntu@$1:chef-bcpc

ssh -i $KEYFILE ubuntu@$1 "cd chef-bcpc && ./setup_ssh_keys.sh $KEYFILE.pub"
host=`ssh -i $KEYFILE ubuntu@$1 "hostname -f"`
ssh -t -i $KEYFILE ubuntu@$1 "cd chef-bcpc && sudo ./setup_chef_server.sh"
ssh -t -i $KEYFILE ubuntu@$1 "cd chef-bcpc && ./setup_chef_cookbooks.sh"
ssh -t -i $KEYFILE ubuntu@$1 "cd chef-bcpc && knife environment from file environments/*.json && knife role from file roles/*.json && knife cookbook upload -a -o cookbooks"

ssh -t -i $KEYFILE ubuntu@$1 "cd chef-bcpc && ./setup_chef_bootstrap_node.sh $1"
