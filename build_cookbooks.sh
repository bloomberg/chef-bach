#!/bin/bash

set -e

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

# Git needs to be installed for Berkshelf to be useful.
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c 'ok installed') -eq 0 ]; then
    sudo apt-get update
    sudo apt-get -y install git
fi

berks install
# FIXME: identify release tag
berks package release_master_cookbooks.tar.gz
