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

export BACH_ENVIRONMENT='Test-Laptop'
export BACH_CLUSTER_PREFIX=${BACH_CLUSTER_PREFIX:-''}
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-5096}
export BOOTSTRAP_VM_CPUs=${BOOTSTRAP_VM_CPUS:-2}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-7120}
export CLUSTER_VM_CPUs=${CLUSTER_VM_CPUs:-4}
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}

BOOTSTRAP_NAME="bcpc-bootstrap"
if [ $BACH_CLUSTER_PREFIX != '' ]; then
  BOOTSTRAP_NAME="${BACH_CLUSTER_PREFIX}-bcpc-bootstrap"
fi

export BOOTSTRAP_NAME

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
echo "Using CLUSTER_PREFIX=${BACH_CLUSTER_PREFIX} VM_LIST=${VM_LIST}"

download_VM_files || ( echo "############## VBOX CREATE DOWNLOAD VM FILES RETURNED $? ##############" && exit 1 )
create_bootstrap_VM || ( echo "############## VBOX CREATE BOOTSTRAP VM RETURNED $? ##############" && exit 1 )

python_to_find_bootstrap_ip="import json; j = json.load(file('${environments[0]}')); print j['override_attributes']['bcpc']['bootstrap']['server']"
BOOTSTRAP_IP=$(python -c "$python_to_find_bootstrap_ip")

create_cluster_VMs || ( echo "############## VBOX CREATE CLUSTER VMs RETURNED $? ##############" && exit 1 )
install_cluster $BACH_ENVIRONMENT $BOOTSTRAP_IP || ( echo "############## VBOX CREATE INSTALL CLUSTER RETURNED $? ##############" && exit 1 )

printf "#### Cobbler Boot\n"
printf "Snapshotting pre-Cobbler and booting (unless already running)\n"

vms_started="False"
for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
  vboxmanage showvminfo $vm | grep -q '^State:.*running' || vms_started="True"
  if [[ ! $(vboxmanage snapshot $vm list --machinereadable | grep -q 'Shoe-less') ]]; then
    vboxmanage showvminfo $vm | grep -q '^State:.*running' || VBoxManage snapshot $vm take Shoe-less
  fi
  vboxmanage showvminfo $vm | grep -q '^State:.*running' || VBoxManage startvm $vm --type headless
done

if hash screen; then
  if [ "$(uname)" == "Darwin" ]; then
    brew install coreutils
    pushd $(greadlink -f $(dirname $0)) > /dev/null
  else
    pushd $(readlink -f $(dirname $0)) > /dev/null
  fi

  # Create a new screenrc with our VM list in it
  cp ./screenrc ../../cluster/screenrc

  echo "cd `pwd`; cd .." >> ../../cluster/screenrc

  ii=1
  for vm in ${VM_LIST[*]}; do
    echo "screen -t \"$vm serial console\" $ii" \
         "./tests/virtualbox_serial_console.sh $vm" >> ../../cluster/screenrc
    ((ii++))
  done
  popd > /dev/null
  echo "Enter this command to view VM serial consoles:"
  echo "  screen -S 'BACH serial consoles' `readlink -f ../cluster/screenrc`"
  echo
fi

vagrant ssh -c "cd chef-bcpc; source proxy_setup.sh; ./wait-for-hosts.sh ${VM_LIST[*]}"
printf "Snapshotting post-Cobbler\n"
for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
  [[ $(vboxmanage snapshot $vm list --machinereadable | grep -q 'Post-Cobble') ]] || \
    [[ "$vms_started" == "True" ]] && VBoxManage snapshot $vm take Post-Cobble --live &
done
wait && printf "Done Snapshotting\n"

printf "#### Chef the nodes with Basic role\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Basic"

printf "Snapshotting Post-Basic\n"
for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
  [[ $(vboxmanage snapshot $vm list --machinereadable | grep -q 'Post-Basic') ]] || \
    VBoxManage snapshot $vm take Basic --live &
done
wait && printf "Done Snapshotting\n"

printf "#### Chef the nodes with complete roles\n"
printf "Cluster type: $CLUSTER_TYPE\n"


# Kafka does not run Bootstrap step
if [ "${CLUSTER_TYPE,,}" == "hadoop" ]; then
  printf "Running C-A-R 'bootstrap' before final C-A-R"
  # https://github.com/bloomberg/chef-bach/issues/847
  # We know the first run might fail set +e
  set +e
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  # if we still fail here we have some other issue
  set -e
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
    [[ $(vboxmanage snapshot $vm list --machinereadable | grep -q 'Post-Bootstrap') ]] || \
      VBoxManage snapshot $vm take Post-Bootstrap --live &
  done
  wait && printf "Done Snapshotting\n"
  printf "Running final C-A-R(s)"
fi

printf "#### Chef machine bcpc-vms with $CLUSTER_TYPE\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE"

# for Hadoop installs we need to re-run the headnodes once HDFS is up to ensure
# we deploy various JARs. Run a second time once a datanode is up.
if [[ "${CLUSTER_TYPE,,}" == "hadoop" ]]; then
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE BCPC-Hadoop-Head"
fi

printf "Snapshotting Post-Install\n"
for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
  [[ $(vboxmanage snapshot $vm list --machinereadable | grep -q 'Post-Install') ]] || \
    VBoxManage snapshot $vm take Post-Install --live &
done
wait && printf "Done Snapshotting\n"

printf '#### Install Completed!\n'
