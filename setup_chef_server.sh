#!/bin/bash

if [ ! -f /etc/apt/sources.list.d/opscode.list ]; then
  cp opscode.list /etc/apt/sources.list.d/
fi

apt-get update && apt-get --allow-unauthenticated -y install opscode-keyring && apt-get update && apt-get install -y chef-server

chmod +r /etc/chef/validation.pem
chmod +r /etc/chef/webui.pem

if [ -f $HOME/.ssh/authorized_keys -a ! -f /root/.ssh/authorized_keys ]; then
  if [ ! -d /root/.ssh ]; then
    mkdir /root/.ssh
  fi
  cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
fi

./cookbooks/bcpc/files/default/build_bins.sh
