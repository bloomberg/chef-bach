#!/bin/bash

# change the following IP address to match your bootstrap node
echo "deb http://100.100.126.11/chef precise-0.10 main" > /etc/apt/sources.list.d/opscode.list

if dpkg -s opscode-keyring 2>/dev/null | grep -q Status.*installed; then
  echo opscode-keyring is installed
else 
  apt-get update
  apt-get --allow-unauthenticated -y install opscode-keyring
  apt-get update
fi

if dpkg -s chef 2>/dev/null | grep -q Status.*installed; then
  echo chef is installed
else
  DEBCONF_DB_FALLBACK=File{$(pwd)/debconf-chef.conf} DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install chef
fi


