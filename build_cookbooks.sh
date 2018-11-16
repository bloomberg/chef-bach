#!/bin/bash

set -e

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

# Git needs to be installed for Berkshelf to be useful.
if ! dpkg -p git >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get -y install git
fi

berks install
# FIXME: identify release tag
berks package release_master_cookbooks.tar.gz
