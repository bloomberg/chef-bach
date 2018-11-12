#!/bin/bash 
# vim: tabstop=2:shiftwidth=2:softtabstop=2
#
# This script originally built a repository with all third-party
# packages required by workers and head nodes.  That repository
# creation process has been moved into the bach_repository cookbook.
#
# Today, this script attempts to build the repo using that cookbook
# with a chef-client running in local mode.
#
set -e

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

DIR=`dirname $0`
mkdir -p $DIR/bins
pushd $DIR/bins/ > /dev/null
apt-get update


popd > /dev/null

pushd lib/cluster-def-gem  > /dev/null
chef gem build cluster_def.gemspec
chef gem install cluster_def*.gem
popd > /dev/null

if pgrep 'chef-client' > /dev/null; then
    echo 'A chef-client run is already underway, aborting build_bins.sh' 1>&2
    exit
fi

#
# We need to use the real Chef cache, even in local mode, so that ark
# cookbook output works correctly on internet-disconnected hosts.
#
mkdir -p /var/chef/cache
TMPFILE=`mktemp -t build_bins_chef_config.XXXXXXXXX.rb`
cat <<EOF > $TMPFILE
cache_path '/var/chef'
no_lazy_load 'true'
EOF

#
# We change to the vendor directory so that chef local-mode finds
# cookbooks in the default path, ./cookbooks
#
# Setting the cookbook path in the config file changes too many other
# defaults.
#
pushd $DIR/vendor > /dev/null
/opt/chefdk/bin/chef-client -z -r 'recipe[bach_repository]' -c $TMPFILE
rm $TMPFILE
popd > /dev/null

