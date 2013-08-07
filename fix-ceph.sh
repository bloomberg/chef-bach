#!/bin/bash

# adjust the following to suit your cluster
NETWORK="10.0.100"

set -x
sed -i -e '/public network/ s/^/#/'  /etc/ceph/ceph.conf
sed -i -e '/cluster network/ s/^/#/' /etc/ceph/ceph.conf
HOST=$(hostname)
ADDR=`ifconfig -a | grep -i $NETWORK | awk '{print $2}' | cut -f2 -d':'`
sudo ceph-mon --cluster=ceph --id=$HOST --public-addr=$ADDR -f
set +x
