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

./vm_to_cluster.rb $*
