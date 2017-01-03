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
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-3096}
export BOOTSTRAP_VM_CPUs=${BOOTSTRAP_VM_CPUS:-2}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-5120}
export CLUSTER_VM_CPUs=${CLUSTER_VM_CPUs:-4}
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}

printf "#### Setup configuration files\n"
# setup vagrant
$SEDINPLACE 's/vb.gui = true/vb.gui = false/' Vagrantfile

# Prepare the test environment file and inject local settings.
if hash ruby; then
  ruby ./tests/edit_environment.rb
else
  printf "WARN: no ruby found -- proceeding without editing environment!\n"
fi

if [ "$CLUSTER_TYPE" == "Kafka" ]; then
    printf "Using kafka_cluster.txt\n"
    cp stub-environment/kafka_cluster.txt ../cluster/cluster.txt
else
    printf "Using hadoop_cluster.txt\n"
    cp stub-environment/hadoop_cluster.txt ../cluster/cluster.txt
fi

# Remove unused files.
rm -f ../cluster/kafka_cluster.txt
rm -f ../cluster/hadoop_cluster.txt

# pull back the modified environment so that it can be copied to remote host
tar -czf cluster.tgz ../cluster

printf "#### Setup VB's and Bootstrap\n"
source ./vbox_create.sh

download_VM_files || ( echo "############## VBOX CREATE DOWNLOAD VM FILES RETURNED $? ##############" && exit 1 )
create_bootstrap_VM || ( echo "############## VBOX CREATE BOOTSTRAP VM RETURNED $? ##############" && exit 1 )

# Copy cluster mutable data to bootstrap.
if [[ -d ../cluster ]]; then
    tar -C .. -cf - cluster | vagrant ssh -c 'cd ~; tar -xvf -'
elif [[ -f ./cluster.tgz ]]; then
    gunzip -c cluster.tgz | vagrant ssh -c 'cd ~; tar -xvf -'
else
    ( echo "############## No cluster data found in ../cluster or ./cluster.tgz! ##############" && exit 1 )
fi

create_cluster_VMs || ( echo "############## VBOX CREATE CLUSTER VMs RETURNED $? ##############" && exit 1 )
install_cluster || ( echo "############## VBOX CREATE INSTALL CLUSTER RETURNED $? ##############" && exit 1 )

printf "#### Install ruby gems\n"
vagrant ssh -c 'cd chef-bcpc; PATH=/opt/chefdk/embedded/bin:/usr/bin:/bin bundle install --path vendor/bundle'

printf "#### Cobbler Boot\n"
printf "Snapshotting pre-Cobbler and booting (unless already running)\n"

if [ "$CLUSTER_TYPE" == "Kafka" ]; then
  VM_LIST=(bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-vm4 bcpc-vm5 bcpc-vm6)
else
  VM_LIST=(bcpc-vm1 bcpc-vm2 bcpc-vm3)
fi

vms_started="False"
for vm in ${VM_LIST[*]} bcpc-bootstrap; do
  vboxmanage showvminfo $vm | grep -q '^State:.*running' || vms_started="True"
  vboxmanage showvminfo $vm | grep -q '^State:.*running' || VBoxManage snapshot $vm take Shoe-less
  vboxmanage showvminfo $vm | grep -q '^State:.*running' || VBoxManage startvm $vm --type headless
done


echo "Checking for GNU screen to watch serial consoles"
if hash screen && [ "$CLUSTER_TYPE" == "Hadoop" ] ; then
    if [ "$(uname)" == "Darwin" ]; then
	brew install coreutils
	pushd $(greadlink -f $(dirname $0))
    else
	pushd $(readlink -f $(dirname $0))
    fi
    screen -S "BACH Install" -c ./screenrc
    popd
else
    while ! nc -w 1 10.0.100.11 22 || \
            ! nc -w 1 10.0.100.12 22 || \
            ! nc -w 1 10.0.100.13 22
    do
	sleep 60
	printf "Hosts down: "
	for m in 11 12 13; do
	    nc -w 1 10.0.100.$m 22 > /dev/null || echo -n "10.0.100.$m "
	done
	printf "\n"
    done

    # HACK: this is a real nice copy/paste.
    if [ "$CLUSTER_TYPE" == "Kafka" ]; then
	while ! nc -w 1 10.0.100.14 22 || \
		! nc -w 1 10.0.100.15 22 || \
		! nc -w 1 10.0.100.16 22
	do
	    sleep 60
	    printf "Hosts down: "
	    for m in 14 15 16; do
		nc -w 1 10.0.100.$m 22 > /dev/null || echo -n "10.0.100.$m "
	    done
	    printf "\n"
	done
    fi
fi

printf "Snapshotting post-Cobbler\n"
for vm in ${VM_LIST[*]} bcpc-bootstrap; do
    [[ "$vms_started" == "True" ]] && VBoxManage snapshot $vm take Post-Cobble --live
done

printf "#### Chef the nodes with Basic role\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT Basic"

printf "Snapshotting post-Basic\n"
for vm in ${VM_LIST[*]} bcpc-bootstrap; do
    VBoxManage snapshot $vm take Basic --live
done

printf "#### Chef the nodes with complete roles\n"
printf "Cluster type: $CLUSTER_TYPE\n"


if [ "$CLUSTER_TYPE" == "Hadoop" ]; then
    printf "Running C-A-R 'bootstrap' before final C-A-R"
    vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT Bootstrap"
    printf "Running final C-A-R"
fi

vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT $CLUSTER_TYPE"

printf "Taking final snapshot\n"
for vm in ${VM_LIST[*]} bcpc-bootstrap; do
    VBoxManage snapshot $vm take Full-Shoes --live
done
