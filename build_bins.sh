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

#
# It's important to install the chefdk before chef, so that
# /usr/bin/knife and /usr/bin/chef-client are symlinks into /opt/chef
# instead of /opt/chefdk.
#
DIR=`dirname $0`
mkdir -p $DIR/bins
pushd $DIR/bins/

if [ $(dpkg-query -W -f='${Status}' chefdk 2>/dev/null | grep -c 'ok installed') -eq 0 ]; then
    wget -nc https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/14.04/x86_64/chefdk_0.12.0-1_amd64.deb

    if ! sha256sum chefdk_0.12.0-1_amd64.deb | grep 6fcb4529f99c212241c45a3e1d024cc1519f5b63e53fc1194b5276f1d8695aaa; then
	echo "Failed to download ChefDK -- wrong checksum."
	exit 1
    else
	dpkg -i chefdk_0.12.0-1_amd64.deb
    fi
fi

popd

if pgrep 'chef-client'; then
    echo 'Chef is already running, aborting build_bins.sh'
    exit
fi

# Git needs to be installed for Berkshelf to be useful.
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c 'ok installed') -eq 0 ]; then
    sudo apt-get -y install git
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
# We change to the vendor directory so that chef local-mode finds
# cookbooks in the default path, ./cookbooks
#
pushd $DIR/vendor
/opt/chefdk/bin/chef-client -z -r 'recipe[bach_repository]'
popd
