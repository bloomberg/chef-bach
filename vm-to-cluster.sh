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
bundle config --local PATH vendor/bundle
bundle config --local DISABLE_SHARED_GEMS true
bundle package --path vendor/bundle
bundle exec --keep-file-descriptors ./vm_to_cluster.rb $*
