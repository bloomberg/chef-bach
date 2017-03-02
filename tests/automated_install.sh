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
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-5096}
export BOOTSTRAP_VM_CPUs=${BOOTSTRAP_VM_CPUS:-2}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-7120}
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
install_cluster $ENVIRONMENT || ( echo "############## VBOX CREATE INSTALL CLUSTER RETURNED $? ##############" && exit 1 )

printf "#### Install ruby gems\n"
vagrant ssh -c 'cd chef-bcpc; source proxy_setup.sh; export PATH=/opt/chefdk/embedded/bin:/usr/bin:/bin; export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig; bundle install --path vendor/bundle'

printf "#### Cobbler Boot\n"
printf "Snapshotting pre-Cobbler and booting (unless already running)\n"

if [ "${CLUSTER_TYPE,,}" == "kafka" ]; then
  VM_LIST=(bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-vm4 bcpc-vm5 bcpc-vm6)
else
  VM_LIST=(bcpc-vm1 bcpc-vm2 bcpc-vm3)
fi

vms_started="False"
for vm in ${VM_LIST[*]} bcpc-bootstrap; do
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
for vm in ${VM_LIST[*]} bcpc-bootstrap; do
  [[ ! $(vboxmanage snapshot $vm list --machinereadable | grep -q 'Post-Cobble') ]] && \
    [[ "$vms_started" == "True" ]] && VBoxManage snapshot $vm take Post-Cobble --live &
done
wait && printf "Done Snapshotting\n"

printf "#### Chef the nodes with Basic role\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT Basic"
printf "Snapshotting Post-Basic\n"
for i in bootstrap vm1 vm2 vm3; do
  [[ $(vboxmanage snapshot bcpc-$i list --machinereadable | grep -q 'Post-Basic') ]] && \
    VBoxManage snapshot bcpc-$i take Post-Basic &
done
wait && printf "Done Snapshotting\n"

printf "#### Chef machine bcpc-vms with Bootstrap\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT Bootstrap"
printf "Snapshotting Post-Bootstrap\n"
for i in bootstrap vm1 vm2 vm3; do
  [[ $(vboxmanage snapshot bcpc-$i list --machinereadable | grep -q 'Post-Bootstrap') ]] && \
    VBoxManage snapshot bcpc-$i take Post-Bootstrap &
done
wait && printf "Done Snapshotting\n"

printf "#### Chef machine bcpc-vms with $CLUSTER_TYPE\n"
vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT $CLUSTER_TYPE"
# for Hadoop installs we need to re-run the headnodes once HDFS is up to ensure
# we deploy various JARs. Run a second time once a datanode is up.
if [[ "${CLUSTER_TYPE,,}" == "hadoop" ]]; then
  vagrant ssh -c "cd chef-bcpc; ./cluster-assign-roles.sh $ENVIRONMENT $CLUSTER_TYPE BCPC-Hadoop-Head"
if
printf "Snapshotting Post-Install\n"
for i in bootstrap vm1 vm2 vm3; do
  [[ $(vboxmanage snapshot bcpc-$i list --machinereadable | grep -q 'Post-Install') ]] && \
    VBoxManage snapshot bcpc-$i take Post-Install &
done
wait && printf "Done Snapshotting\n"

printf '#### Install Completed!\n'
