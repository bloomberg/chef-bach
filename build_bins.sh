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

# Clean up any left-behind chef config from prior runs.
rm -f /tmp/build_bins_chef_config.?????????.rb

DIR=`dirname $0`
mkdir -p $DIR/bins
pushd $DIR/bins/ > /dev/null
apt-get update

chefdk_vers='1.6.11'
chefdk_dpkg="chefdk_${chefdk_vers}-1_amd64.deb"
chefdk_sha256='a89f0ef2a8edbefbbf4cb14d8d97f83e9227fff35f2d80fb45b03604c91a207b'
if [ ! -f ${chefdk_dpkg} ] || ! sha256sum ${chefdk_dpkg} | grep -q ${chefdk_sha256}; then
    rm -f ${chefdk_dpkg}
    # $CURL is defined in proxy_setup.sh
    $CURL -O -J https://packages.chef.io/files/stable/chefdk/${chefdk_vers}/ubuntu/14.04/${chefdk_dpkg}

    if ! sha256sum ${chefdk_dpkg} | grep -q ${chefdk_sha256}; then
	echo 'Failed to download ChefDK -- wrong checksum.' 1>&2
	exit 1
    fi
fi

if [ $(dpkg-query -W -f='${Status}' chefdk 2>/dev/null | grep -c 'ok installed') -eq 0 ]; then
    dpkg -i ${chefdk_dpkg}
fi

popd > /dev/null

pushd lib/cluster-def-gem  > /dev/null
/opt/chefdk/embedded/bin/gem build cluster_def.gemspec
sudo /opt/chefdk/embedded/bin/gem install cluster_def
popd > /dev/null

chef_client_run=$(pgrep -u root -a -f 'chef-client worker' || true)
if [ -n "${chef_client_run}" ]; then
    echo -e 'A chef-client run is already underway, aborting build_bins.sh:\n' \
            "${chef_client_run}" 1>&2
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
    /opt/chefdk/bin/berks vendor $DIR/vendor/cookbooks
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
/opt/chefdk/bin/chef-client -z -r 'recipe[bcpc::bach_repository_wrapper],recipe[bach_repository]' -c $TMPFILE
rm $TMPFILE
popd > /dev/null

