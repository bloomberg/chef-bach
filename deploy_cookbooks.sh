#!/bin/bash

set -x
# Location of cookbooks tarball to download
cookbooks_url=$1

#
# Only vendor cookbooks if the directory is absent.
# We don't want to overwrite a cookbooks tarball dropped off by the user!
#
if [[ ! -d $DIR/vendor/cookbooks/bach_repository ]]; then
  mkdir -p vendor
  curl $cookbooks_url | tar -xvz -C ./vendor
  # For some reason, tar -C changes ./vendor's permissions to 700
  chmod 755 vendor
else
  echo "Found $DIR/vendor/cookbooks/bach_repository, not invoking Berkshelf"
fi
