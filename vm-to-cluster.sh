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

# Iterate over a list of "<dpkg name> <gem name>" necessary for the Gemfile
for p in "libaugeas-dev ruby-augeas" "libmysqlclient-dev mysql2" "libmysqld-dev mysql2" "libkrb5-dev rkerberos"; do 
  if [ $(dpkg-query -W -f='${Status}' ${p% *} 2>/dev/null | grep -c 'ok installed') -ne 1 ] && [ "$(uname)" != "Darwin" ]; then
    echo "#### Need ${p% *} for the ${p#* } Gem" > /dev/stderr
    sudo apt-get install -y ${p% *}
  fi
done

export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
bundle config --local PATH vendor/bundle
bundle config --local DISABLE_SHARED_GEMS true
bundle package --path vendor/bundle
bundle exec --keep-file-descriptors ./vm_to_cluster.rb $*
