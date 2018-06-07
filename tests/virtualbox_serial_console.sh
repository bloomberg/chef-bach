#!/bin/bash

# Check we got a VM name
if [[ "$#" != 1 ]]; then
  echo "Usage: $(basename $0) <vm name>" >> /dev/stderr
  echo -e '\tNeed the name of a VM to connect to' >> /dev/stderr
  exit 2
fi
vm_name="$1"

source $(readlink -f $(dirname $0)/..)/virtualbox_env.sh

# If we are running on Ubuntu check socat(1) is installed
socat_install_cmd='sudo apt-get install -y socat'
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  if [ "$(lsb_release -si)" == "Ubuntu" -a \
     -z "$(dpkg -s socat 2>/dev/null | grep '^Status.*installed')" ]; then
    echo "Did not find socat(1) installed; running: $socat_install_cmd" >> /dev/stderr
    $socat_install_cmd
  fi
fi

$VBM list runningvms | grep -q "\"$vm_name\"" || (echo "VM name: $1 not found"; exit 1)
serial_socket=$($VBM showvminfo $vm_name | grep '^UART 1:' | sed -e "s/.* '//" -e "s/'$//")

trap "stty sane" 0 1 2 3 15
socat unix-connect:$serial_socket stdio,raw,echo=0,icanon=0
