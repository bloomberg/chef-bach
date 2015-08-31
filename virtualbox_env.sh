#!/bin/bash

# Source this file at the top of your script when needing VBoxManage
# e.g.,
# source ./virtualbox_env.sh

if [[ -z "$VBM" ]]; then

    if ! command -v VBoxManage >& /dev/null; then
        echo "VBoxManage not found!" >&2
        echo "  Please ensure VirtualBox is installed and VBoxManage is on your system PATH." >&2
        exit 1
    fi

    function check_version {
        local MIN_VERSION="4.3"
        local version=`VBoxManage --version | perl -ne 'm/(\d\.\d)\./; print "$1"'`

        if ! echo "$version >= $MIN_VERSION" | bc | grep 1 > /dev/null
        then
            echo "ERROR: VirtualBox $version is less than $MIN_VERSION.x!" >&2
            echo "  Only VirtualBox >= $MIN_VERSION.x is officially supported." >&2
            exit 1
        fi
    }

    check_version
    unset -f check_version

    export VBM=VBoxManage
fi
