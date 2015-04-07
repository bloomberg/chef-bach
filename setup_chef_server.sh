#!/bin/bash

#
# This script expects to be run in the chef-bcpc directory
#

set -e
set -x

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
  # Create an Apt repo entry
  echo "deb [arch=amd64] file://$(pwd)/bins/ 0.5.0 main" > /etc/apt/sources.list.d/bcpc.list
  # add repo key
  apt-key add bins/apt_key.pub
  # update only the BCPC local repo
  apt-get -o Dir::Etc::SourceList=/etc/apt/sources.list.d/bcpc.list,Dir::Etc::SourceParts= update
fi

if dpkg -s chef 2>/dev/null | grep -q ^Status.*installed && \
   dpkg -s chef 2>/dev/null | grep -q ^Version.*11; then
  echo chef is installed
else
  apt-get -y install chef
  /opt/chef/embedded/bin/gem sources --add file://$(pwd)/bins/
  /opt/chef/embedded/bin/gem sources --remove http://rubygems.org/
fi

# setup OpenStack hint
mkdir -p /etc/chef/ohai/hints/
touch /etc/chef/ohai/hints/openstack.json

if dpkg -s chef-server 2>/dev/null | grep -q ^Status.*installed && \
   dpkg -s chef 2>/dev/null | grep -q ^Version.*11; then
  echo chef-server is installed
else
  apt-get -y install chef-server
  mkdir /etc/chef-server
  printf "chef_server_webui['enable'] = false\n" >> /etc/chef-server/chef-server.rb
  printf "nginx['enable_non_ssl'] = false\n" >> /etc/chef-server/chef-server.rb
  printf "nginx['non_ssl_port'] = 4000\n" >> /etc/chef-server/chef-server.rb
  # we can take about 45 minutes to Chef the first machine when running on VMs
  # so follow tuning from CHEF-4253
  printf "erchef['s3_url_ttl'] = 3600\n" >> /etc/chef-server/chef-server.rb
  chef-server-ctl reconfigure
fi

# copy our ssh-key to be authorized for root
if [[ -f $HOME/.ssh/authorized_keys && ! -f /root/.ssh/authorized_keys ]]; then
  if [[ ! -d /root/.ssh ]]; then
    mkdir /root/.ssh
  fi
  cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
fi

./build_bins.sh

if [[ ! -f /etc/apt/sources.list.d/bcpc.list ]]; then
  # Create an Apt repo entry
  echo "deb [arch=amd64] file://$(pwd)/bins/ 0.5.0 main" > /etc/apt/sources.list.d/bcpc.list
  # add repo key
  apt-key add bins/apt_key.pub
  # update only the BCPC local repo
  apt-get -o Dir::Etc::SourceList=/etc/apt/sources.list.d/bcpc.list,Dir::Etc::SourceParts= update
fi
