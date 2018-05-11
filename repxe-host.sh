#!/bin/bash
#
# This shell stub invokes the repxe_host.rb script using the
# binary gems pre-installed in vendor/bootstrap.
#
# See repxe_host.rb for a detailed description.
#
export PATH=/opt/chefdk/embedded/bin:/usr/bin:/bin

REPO_DIR="`dirname ${BASH_SOURCE[0]}`"
cd $REPO_DIR
bundle exec --keep-file-descriptors $PWD/repxe_host.rb $*

