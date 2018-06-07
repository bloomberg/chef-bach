#!/bin/bash

# set -x # builtin command printing
set -e # builtin immediate exit

################################################################################
# This script designed to provide a complete one-touch install of Chef-BCPC in
# an environment with a proxy and custom DNS servers; VMs booted headlessly
# simple few environment variables to tune booting for fast testing of Chef-BCPC
# Run this script in the root of the git repository
################################################################################

# Export Resource Allocation
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-5096}
export BOOTSTRAP_VM_CPUs=${BOOTSTRAP_VM_CPUS:-2}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-7120}
export CLUSTER_VM_CPUs=${CLUSTER_VM_CPUs:-4}
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}

# Export BACH Repo and VM Cluster Environment
export PATH=/opt/chefdk/embedded/bin:$PATH
export BACH_ENVIRONMENT='Test-Laptop'
export BACH_CLUSTER_PREFIX=${BACH_CLUSTER_PREFIX:-''}
export BACH_REPO_DIR=$(git rev-parse --show-toplevel)
export BACH_CLUSTER_DIR=${BACH_REPO_DIR}/../cluster

if [[ $(pwd) != $BACH_REPO_DIR ]]; then
  printf "#### WARNING: This should be run in the git top level directory! ####\n" >/dev/stderr
fi

export BOOTSTRAP_NAME="bcpc-bootstrap"
if [[ -n $BACH_CLUSTER_PREFIX ]]; then
  export BOOTSTRAP_NAME="${BACH_CLUSTER_PREFIX}-${BOOTSTRAP_NAME}"
fi

# OS-Specific Dependencies
if [ "$(uname)" == "Darwin" ]; then
  brew install coreutils
  READLINK=greadlink
  SEDINPLACE='sed -i ""'
else
  READLINK=readlink
  SEDINPLACE='sed -i'
fi

#### Setup Configuration files
printf "#### Setup configuration files\n"
$SEDINPLACE 's/vb.gui = true/vb.gui = false/' Vagrantfile

# Prepare the test environment file and inject local settings.
if hash ruby; then
  ruby ./tests/edit_environment.rb
else
  printf "#### WARNING: no ruby found -- proceeding without editing environment!\n" >/dev/stderr
  mkdir -p $BACH_CLUSTER_DIR && cp -rv stub-environment/* $BACH_CLUSTER_DIR
fi

# Set cluster environment
# normalize capitaliztion of CLUSTER_TYPE to lower case
typeset -l CLUSTER_TYPE="${CLUSTER_TYPE}"
if [ "${CLUSTER_TYPE}" == "kafka" ]; then
  printf "Cluster type(${CLUSTER_TYPE}): (kafka_cluster.txt)\n"
  cp stub-environment/kafka_cluster.txt $BACH_CLUSTER_DIR/cluster.txt
elif [ "${CLUSTER_TYPE}" == "hadoop" ]; then
  printf "Cluster type(${CLUSTER_TYPE}): (hadoop_cluster.txt)\n"
  cp stub-environment/hadoop_cluster.txt $BACH_CLUSTER_DIR/cluster.txt
else
  printf "#### WARNING: unsupported cluster type: ${CLUSTER_TYPE}\n" >/dev/stderr
fi

# Remove unused files.
rm -f $BACH_CLUSTER_DIR/kafka_cluster.txt
rm -f $BACH_CLUSTER_DIR/hadoop_cluster.txt

#### Setup Virtualbox VMs and Bootstrap
printf "#### Setup VB's and Bootstrap\n"
source ./vbox_create.sh

# Ensure we got VM_LIST from vbox_create.sh
echo "CLUSTER_PREFIX: ${BACH_CLUSTER_PREFIX}"
echo "VM LIST: "; for vm in ${VM_LIST[*]}; do echo $vm; done

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

python_to_find_bootstrap_ip="
import json;
j = json.load(file('${environments[0]}'));
print j['override_attributes']['bcpc']['bootstrap']['server']
"
BOOTSTRAP_IP=$(python -c "$python_to_find_bootstrap_ip")

create_cluster_VMs || ( echo "############## VBOX CREATE CLUSTER VMs RETURNED $? ##############" && exit 1 )
install_cluster $BACH_ENVIRONMENT $BOOTSTRAP_IP || ( echo "############## VBOX CREATE INSTALL CLUSTER RETURNED $? ##############" && exit 1 )

printf "#### Cobbler Boot\n"
printf "Snapshotting pre-Cobbler and booting (unless already running)\n"
snapshotVMs "${SNAP_PRE_PXE}"
for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
  vboxmanage showvminfo $vm --machinereadable | grep -q '^VMState="running"$' ||
  vboxmanage startvm $vm --type headless
done

WAIT_FOR_HOSTS=\
"vagrant ssh -c 'cd chef-bcpc; source proxy_setup.sh; ./wait-for-hosts.sh ${VM_LIST[*]};'"
if hash screen; then
  # Create a new screenrc with our VM list in it
  SCREENRC=$BACH_CLUSTER_DIR/screenrc
  cp tests/screenrc $SCREENRC
  echo "cd $BACH_REPO_DIR" >> $SCREENRC

  echo "Starting vm serial consoles (${VM_LIST[*]})"
  SERIAL_CONSOLE="$BACH_REPO_DIR/tests/virtualbox_serial_console.sh"
  KILL_CONSOLES="pgrep -f $SERIAL_CONSOLE | xargs kill -9"
  for vm in ${VM_LIST[*]}; do
    echo "screen -t \"$vm serial console\" -- $SERIAL_CONSOLE $vm" >> $SCREENRC
  done

  echo "screen -t \"Wait For Hosts\" -- bash -c \"$WAIT_FOR_HOSTS && $KILL_CONSOLES\"" >> $SCREENRC;
  screen -S 'BACH VM Install Progress' -c $SCREENRC
else
  echo "#### WARNING: Did not find screen -- please use " \
    "tests/virtualbox_serial_console.sh " \
    "<vm name> if you need a serial console." > /dev/stderr
  bash -c "$WAIT_FOR_HOSTS"
fi

printf "Finished waiting for hosts to boot.\n"
snapshotVMs "${SNAP_POST_PXE}"

printf "#### Chef the nodes with Basic role\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Basic"
snapshotVMs "${SNAP_POST_BASIC}"

printf "#### Chef the nodes with complete roles\n"
printf "Cluster type: $CLUSTER_TYPE\n"

# Kafka does not run Bootstrap step
if [ "${CLUSTER_TYPE}" == "hadoop" ]; then
  printf "Running C-A-R 'bootstrap' before final C-A-R\n"
  # https://github.com/bloomberg/chef-bach/issues/847
  # We know the first run might fail set +e
  set +e
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  set -e
  # if we still fail here we have some other issue
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  snapshotVMs "${SNAP_POST_BOOTSTRAP}"
  printf "Running final C-A-R(s)\n"
fi

printf "#### Chef machine bcpc-vms with $CLUSTER_TYPE\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE"

# for Hadoop installs we need to re-run the headnodes once HDFS is up to ensure
# we deploy various JARs. Run a second time once a datanode is up.
if [[ "${CLUSTER_TYPE}" == "hadoop" ]]; then
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE BCPC-Hadoop-Head"
fi
snapshotVMs "${SNAP_POST_INSTALL}"

printf "#### Install Completed!\n"
