#!/bin/bash

# Check we got a VM name
if [[ "$#" != 1 ]]; then
  echo "Usage: $(basename $0) <vm name>" >> /dev/stderr
  echo -e '\tNeed the name of a VM to connect to' >> /dev/stderr
  exit 2
fi
vm_name="$1"

# If we are running on Ubuntu check netcat(1) is installed
if [[
  "$OSTYPE" == "linux-gnu"
  && "$(lsb_release -si)" == "Ubuntu"
  && -z "$(dpkg -s netcat-openbsd 2>/dev/null | grep '^Status.*installed')"
]]; then
  netcat_install_cmd='sudo apt-get install -y netcat-openbsd'
  echo "Did not find netcat(1) installed; running: $netcat_install_cmd" >> /dev/stderr
  $netcat_install_cmd
fi

source $(readlink -f $(dirname $0)/..)/virtualbox_env.sh
$VBM list runningvms | grep -q "\"$vm_name\"" || (echo "VM name: $1 not found"; exit 1)
serial_socket=$($VBM showvminfo $vm_name | grep '^UART 1:' | sed -e "s/.* '//" -e "s/'$//")

# trap "stty sane" 0 1 2 3 15
# socat unix-connect:$serial_socket stdio,raw,echo=0,icanon=0
nc -U $serial_socket
