#!/bin/bash

################################################################################
# This script designed to provide a complete one-touch install of Chef-BCPC in
# an environment with a proxy and custom DNS servers; VMs booted headlessly
# simple few environment variables to tune booting for fast testing of Chef-BCPC
# Run this script in the root of the git repository
#

set -e

if [ "$(uname)" == "Darwin" ]; then
  SEDINPLACE='sed -i ""'
else
  SEDINPLACE='sed -i'
fi

if [[ "$(pwd)" != "$(git rev-parse --show-toplevel)" ]]; then
  printf '#### WARNING: This should be run in the git top level directory! ####\n' > /dev/stderr
fi

ENVIRONMENT=Test-Laptop
#PROXY=proxy.example.com:80
DNS_SERVERS='"8.8.8.8", "8.8.4.4"'
export BOOTSTRAP_VM_MEM=3096
export BOOTSTRAP_VM_CPUs=2
export CLUSTER_VM_MEM=5120
export CLUSTER_VM_CPUs=4

printf "#### Setup configuration files\n"
# setup vagrant
$SEDINPLACE 's/vb.gui = true/vb.gui = false/' Vagrantfile

# setup proxy_setup.sh
[[ -n "$PROXY" ]] && $SEDINPLACE "s/#export PROXY=.*\"/export PROXY=\"$PROXY\"/" proxy_setup.sh

# setup environment file
$SEDINPLACE "s/\"dns_servers\" : \[ \"8.8.8.8\", \"8.8.4.4\" \]/\"dns_servers\" : \[ $DNS_SERVERS \]/" environments/${ENVIRONMENT}.json
[[ -n "$PROXY" ]] && $SEDINPLACE -e "s#\(\"bootstrap\": {\)#\1\\\n\"proxy\" : \"http://$PROXY\",#" -e $'s/\\\\n/\\\n/' environments/${ENVIRONMENT}.json

printf "#### Setup VB's and Bootstrap\n"
source ./vbox_create.sh

download_VM_files || ( echo "############## VBOX CREATE DOWNLOAD VM FILES RETURNED $? ##############" && exit 1 )
create_bootstrap_VM || ( echo "############## VBOX CREATE BOOTSTRAP VM RETURNED $? ##############" && exit 1 )
create_cluster_VMs || ( echo "############## VBOX CREATE CLUSTER VMs RETURNED $? ##############" && exit 1 )
install_cluster || ( echo "############## VBOX CREATE INSTALL CLUSTER RETURNED $? ##############" && exit 1 )

printf "#### Cobbler Boot\n"
printf "Snapshotting pre-Cobbler and booting (unless already running)\n"
vms_started="False"
for i in 1 2 3; do
  vboxmanage showvminfo bcpc-vm$i | grep -q '^State:.*running' || vms_started="True"
  vboxmanage showvminfo bcpc-vm$i | grep -q '^State:.*running' || VBoxManage snapshot bcpc-vm$i take Shoe-less
  vboxmanage showvminfo bcpc-vm$i | grep -q '^State:.*running' || VBoxManage startvm bcpc-vm$i --type headless
done

printf "Checking VMs are up: \n"
while ! nc -w 1 10.0.100.11 22 || \
         !  nc -w 1 10.0.100.12 22 || \
         !  nc -w 1 10.0.100.13 22
do
  sleep 60
  printf "Hosts down: "
  for m in 11 12 13; do
    nc -w 1 10.0.100.$m 22 > /dev/null || echo -n "10.0.100.$m "
  done
  printf "\n"
done

printf "Snapshotting post-Cobbler\n"
[[ "$vms_started" == "True" ]] && VBoxManage snapshot bcpc-vm1 take Post-Cobble
[[ "$vms_started" == "True" ]] && VBoxManage snapshot bcpc-vm2 take Post-Cobble
[[ "$vms_started" == "True" ]] && VBoxManage snapshot bcpc-vm3 take Post-Cobble

printf "#### Chef all the nodes\n"
vagrant ssh -c "sudo apt-get install -y sshpass"

printf "#### Chef machine bcpc-vms\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT Basic"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT Hadoop"

printf "Snapshotting post-Cobbler\n"
VBoxManage snapshot bcpc-vm1 take Full-Shoes
VBoxManage snapshot bcpc-vm2 take Full-Shoes
VBoxManage snapshot bcpc-vm3 take Full-Shoes
