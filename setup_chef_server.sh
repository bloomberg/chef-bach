#!/bin/bash

#
# This script expects to be run in the chef-bcpc directory
#

set -e

if [ -f ./proxy_setup.sh ]; then
  . ./proxy_setup.sh
fi

# needed within build_bins which we call
if [ -z "$CURL" ]; then
	echo "CURL is not defined"
	exit
fi

if [ ! -f /etc/apt/sources.list.d/opscode.list ]; then
  cp opscode.list /etc/apt/sources.list.d/
fi

apt-get update
apt-get --allow-unauthenticated -y install opscode-keyring
apt-get update
DEBCONF_DB_FALLBACK=File{$(pwd)/debconf-chef.conf} DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install chef
DEBCONF_DB_FALLBACK=File{$(pwd)/debconf-chef.conf} DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install chef-server

chmod +r /etc/chef/validation.pem
chmod +r /etc/chef/webui.pem

# copy our ssh-key to be authorized for root
if [ -f $HOME/.ssh/authorized_keys -a ! -f /root/.ssh/authorized_keys ]; then
  if [ ! -d /root/.ssh ]; then
    mkdir /root/.ssh
  fi
  cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
fi

./cookbooks/bcpc/files/default/build_bins.sh
