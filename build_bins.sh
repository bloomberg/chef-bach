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

# Git needs to be installed for Berkshelf to be useful.
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c 'ok installed') -eq 0 ]; then
    apt-get update
    apt-get -y install git
fi

#
# Only vendor cookbooks if the directory is absent.
# We don't want to overwrite a cookbooks tarball dropped off by the user!
#
if [[ ! -d $DIR/vendor/cookbooks/bach_repository ]]; then
    berks vendor $DIR/vendor/cookbooks
else
    echo "Found $DIR/vendor/cookbooks/bach_repository, not invoking Berkshelf"
fi

# Don't allow Berkshelf output to be owned by root.
if [[ ! -z "$SUDO_USER" ]]; then
    chown -R $SUDO_USER $DIR/vendor
    chown $SUDO_USER $DIR/Berksfile.lock
    chown -R $SUDO_USER $HOME/.berkshelf
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

