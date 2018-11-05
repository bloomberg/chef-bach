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

export BACH_ENVIRONMENT=${BACH_ENVIRONMENT:-'Test-Laptop'}
export BACH_CLUSTER_PREFIX=${BACH_CLUSTER_PREFIX:-''}
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}
export PATH=/opt/chefdk/embedded/bin:$PATH

# normalize capitaliztion of CLUSTER_TYPE to lower case
typeset -l CLUSTER_TYPE="${CLUSTER_TYPE}"

printf "#### Setup configuration files\n"
# setup vagrant
$SEDINPLACE 's/vb.gui = true/vb.gui = false/' Vagrantfile

# Prepare the test environment file and inject local settings.
if hash ruby; then
  ruby ./tests/edit_environment.rb
else
  printf "#### WARNING: no ruby found -- proceeding without editing environment!\n" > /dev/stderr
  mkdir -p ../cluster
  cp -rv stub-environment/* ../cluster
fi

if [ "${CLUSTER_TYPE,,}" == "kafka" ]; then
  printf "Using kafka_cluster.txt\n"
  cp stub-environment/kafka_cluster.txt ../cluster/cluster.txt
else
  printf "Using hadoop_cluster.txt\n"
  cp stub-environment/hadoop_cluster.txt ../cluster/cluster.txt
fi

# Remove unused files.
rm -f ../cluster/kafka_cluster.txt
rm -f ../cluster/hadoop_cluster.txt

printf "#### Setup VB's and Bootstrap\n"
source ./vbox_create.sh

# Ensure we got VM_LIST from vbox_create.sh
echo "Using CLUSTER_PREFIX=${BACH_CLUSTER_PREFIX}"
echo "VM LIST"
for vm in ${VM_LIST[*]}; do
  echo $vm
done

# VM Snapshot Statemachine:
# Before PXE boot:
SNAP_PRE_PXE='Shoe-less'
# After OS Install:
SNAP_POST_PXE='Post-Cobble'
# After cluster-assign-roles Bootstrap Step:
SNAP_POST_BASIC='Post-Basic'
# After cluster-assign-roles <cluster> Step:
SNAP_POST_BOOTSTRAP='Post-Bootstrap'
# After cluster-assign-roles <cluster> Step:
SNAP_POST_INSTALL='Post-Install'


download_VM_files || ( echo "############## VBOX CREATE DOWNLOAD VM FILES RETURNED $? ##############" && exit 1 )
create_bootstrap_VM || ( echo "############## VBOX CREATE BOOTSTRAP VM RETURNED $? ##############" && exit 1 )

python_to_find_bootstrap_ip="import json; j = json.load(file('${environments[0]}')); print j['override_attributes']['bcpc']['bootstrap']['server']"
BOOTSTRAP_IP=$(python -c "$python_to_find_bootstrap_ip")

create_cluster_VMs || ( echo "############## VBOX CREATE CLUSTER VMs RETURNED $? ##############" && exit 1 )
install_cluster $BACH_ENVIRONMENT $BOOTSTRAP_IP || ( echo "############## VBOX CREATE INSTALL CLUSTER RETURNED $? ##############" && exit 1 )

printf "#### Cobbler Boot\n"
printf "  Snapshotting pre-Cobbler and booting (unless already running)\n"
snapshotVMs "${SNAP_PRE_PXE}"
for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
  vboxmanage showvminfo $vm --machinereadable | grep -q '^VMState="running"$' || \
    VBoxManage startvm $vm --type headless
done

vagrant ssh -c "cd chef-bcpc; source proxy_setup.sh; ./wait-for-hosts.sh ${VM_LIST[*]}"
snapshotVMs "${SNAP_POST_PXE}"

printf "#### Chef the nodes with Basic role\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Basic"
snapshotVMs "${SNAP_POST_BASIC}"

printf "#### Chef the nodes with complete roles\n"
printf "Cluster type: $CLUSTER_TYPE\n"

# Kafka does not run Bootstrap step
if [ "${CLUSTER_TYPE,,}" == "hadoop" ]; then
  printf "Running C-A-R 'bootstrap' before final C-A-R"
  # https://github.com/bloomberg/chef-bach/issues/847
  # We know the first run might fail set +e
  set +e
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  set -e
  # if we still fail here we have some other issue
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  snapshotVMs "${SNAP_POST_BOOTSTRAP}"
  printf "Running final C-A-R(s)"
fi

printf "#### Chef machine bcpc-vms with $CLUSTER_TYPE\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE"

# for Hadoop installs we need to re-run the headnodes once HDFS is up to ensure
# we deploy various JARs. Run a second time once a datanode is up.
if [[ "${CLUSTER_TYPE,,}" == "hadoop" ]]; then
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE BCPC-Hadoop-Head"
fi
snapshotVMs "${SNAP_POST_INSTALL}"

printf '#### Install Completed!\n'
