#!/bin/bash

#
# This script expects to be run in the chef-bcpc directory
#

set -e

# Default to Test-Laptop if environmnet not passed in
ENVIRONMENT="${1-Test-Laptop}"

# We may need the proxy for apt-get later
if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

if [[ -z "$CURL" ]]; then
  echo "CURL is not defined"
  exit
fi

if [[ ! -f /etc/apt/sources.list.d/bcpc.list ]]; then
  # Ensure we are set to use the bootstrap server's repo
  bootstrap_server_key='["override_attributes"]["bcpc"]["bootstrap"]["server"]'
  binary_server_key='["override_attributes"]["bcpc"]["binary_server_url"]'
  load_json_frag="import json; print json.load(file('environments/${ENVIRONMENT}.json'))"
  # return a full URL (e.g. http://127.0.0.1:8080)
  apt_server=$(python -c "${load_json_frag}$binary_server_key" 2>/dev/null||\
               (echo -n "http://"; \
                python -c "${load_json_frag}${bootstrap_server_key}+':8080'"))
  # create an Apt repo entry
  echo "deb ${apt_server} /" > /etc/apt/sources.list.d/bcpc.list
  # update only the BCPC local repo
  apt-get -o Dir::Etc::SourceList=/etc/apt/sources.list.d/bcpc.list,Dir::Etc::SourceParts= update
fi 

if dpkg -s chef 2>/dev/null | grep -q ^Status.*installed && \
   dpkg -s chef 2>/dev/null | grep -q ^Version.*11; then
  echo chef is installed
else
  apt-get -y install chef
fi

if dpkg -s chef-server 2>/dev/null | grep -q ^Status.*installed && \
   dpkg -s chef 2>/dev/null | grep -q ^Version.*11; then
  echo chef-server is installed
else
  apt-get -y install chef-server
  chef-server-ctl reconfigure
fi

# copy our ssh-key to be authorized for root
if [[ -f $HOME/.ssh/authorized_keys && ! -f /root/.ssh/authorized_keys ]]; then
  if [[ ! -d /root/.ssh ]]; then
    mkdir /root/.ssh
  fi
  cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
fi
