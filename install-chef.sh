#!/bin/bash
set -e
# if you dont have internet access from your cluster nodes, you will
# not be able to "knife bootstrap" nodes to get them ready for
# chef. Instead you need to install chef separately. Assuming the
# necessary bits are hosted on your binary_server_url as setup by
# build_bins.sh this will allow you to proceed

BINARY_SERVER_HOST=${1:?"Need a Binary Server Host"}
BINARY_SERVER_URL=${2:?"Need a Binary Server URL"}

grep -q $BINARY_SERVER_HOST /etc/apt/apt.conf || echo "Acquire::http::Proxy::$BINARY_SERVER_HOST 'DIRECT';" >> /etc/apt/apt.conf
echo "deb $BINARY_SERVER_URL /" > /etc/apt/sources.list.d/bcpc.list
wget --no-proxy -O - ${BINARY_SERVER_URL}/apt_key.pub | apt-key add -
# update only the BCPC repo
apt-get -o Dir::Etc::SourceList=/etc/apt/sources.list.d/bcpc.list,Dir::Etc::SourceParts= update
apt-get install -y chef
