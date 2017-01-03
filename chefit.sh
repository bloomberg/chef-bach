#!/bin/bash

set -e
set -o nounset

IP="${1:?"Need the IP of a machine to install"}"
ENVIRONMENT="${2:?"Need the Chef environment to use"}"

echo "initial configuration of $IP"

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

load_binary_server_info $ENVIRONMENT
load_chef_server_ip

SCPCMD="./nodescp    $ENVIRONMENT $IP"
SSHCMD="./nodessh.sh $ENVIRONMENT $IP"

echo "copy files..."
for f in install-chef.sh; do
  $SCPCMD $f ubuntu@$IP:/home/ubuntu || (echo "copying $f failed" > /dev/stderr; exit 1)
done

if [[ -n "$(source proxy_setup.sh >/dev/null; echo ${http_proxy-})" ]]; then
  PROXY=$(source proxy_setup.sh >/dev/null; echo $http_proxy)
  echo "setting up .wgetrc's to $http_proxy"
  $SSHCMD "echo \"http_proxy = $http_proxy\" > .wgetrc"
fi

# remove deb-src lines (we do not mirror them and should not need them)
$SSHCMD "sed -i 's/^deb-src/\#deb-src/g' /etc/apt/sources.list" sudo

echo "setup chef"
$SSHCMD "/home/ubuntu/install-chef.sh $binary_server_host $binary_server_url $chef_server_ip `hostname`" sudo

echo "done."
