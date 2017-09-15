#!/bin/bash
#
# This shell stub invokes the vm_to_cluster.rb script using the
# binary gems pre-installed in vendor/bundle.
#
# See wait_for_hosts.rb for a detailed description.
#
export PATH=/opt/chefdk/embedded/bin:/usr/bin:/bin

REPO_DIR="`dirname ${BASH_SOURCE[0]}`"
cd $REPO_DIR
. ./proxy_setup.sh

if [ $(dpkg-query -W -f='${Status}' libaugeas-dev 2>/dev/null | grep -c 'ok installed') -ne 1 ] && [ "$(uname)" != "Darwin" ]; then
  echo "#### Need libaugeas-dev for the Augeas Gem" > /dev/stderr
  sudo apt-get install -y libaugeas-dev
fi

if [ $(dpkg-query -W -f='${Status}' libkrb5-dev 2>/dev/null | grep -c 'ok installed') -ne 1 ] && [ "$(uname)" != "Darwin" ]; then
  echo "#### Need libkrb5-dev for the rkerberos Gem" > /dev/stderr
  sudo apt-get install -y libkrb5-dev
fi

export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
bundle config --local PATH vendor/bundle
bundle config --local DISABLE_SHARED_GEMS true
bundle package --path vendor/bundle > /dev/null
bundle exec --keep-file-descriptors ./vm_to_cluster.rb $*
