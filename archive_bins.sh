#!/bin/bash

# Meant to be run inside the hypervisor

log_pretty() {
  sed 's/^/     /'
}

set -e

printf "###> Archiving bins\n"

tarball_name=${1-release_master_bins.tar.gz}

set -x

vagrant ssh -c "tar cvpzf ~/${tarball_name} -C ~/chef-bcpc \
    --exclude=bins/apt_key.* --exclude=bins/Release.gpg \
    bins vendor/bootstrap vendor/cache gemfiles" | log_pretty
vagrant ssh -c "cp -fv  ~/${tarball_name} \
    /chef-bcpc-host/${tarball_name}" | log_pretty
mv -v ${tarball_name} ../${tarball_name} | log_pretty

set +x
printf "Bins tarball in ../${tarball_name}\n" | log_pretty
