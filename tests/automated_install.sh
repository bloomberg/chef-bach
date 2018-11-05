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
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-5096}
export BOOTSTRAP_VM_CPUs=${BOOTSTRAP_VM_CPUS:-2}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-7120}
export CLUSTER_VM_CPUs=${CLUSTER_VM_CPUs:-4}
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}
export PATH=/opt/chefdk/embedded/bin:$PATH

BOOTSTRAP_NAME="bcpc-bootstrap"
if [ "$BACH_CLUSTER_PREFIX" != "" ]; then
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

#
# Copy local config files into place. (See vbox_create.sh)
#
copy_local_configuration

#
# Invoke Vagrant to spin up VMs with blank OS images.
#
create_cluster_VMs

printf "#### Chef the nodes with Basic role\n"
vagrant ssh bootstrap -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Basic"

printf "#### Chef the nodes with complete roles\n"
printf "Cluster type: $CLUSTER_TYPE\n"

# Kafka does not run Bootstrap step
if [ "${CLUSTER_TYPE,,}" == "hadoop" ]; then
  printf "Running C-A-R 'bootstrap' before final C-A-R"
  # https://github.com/bloomberg/chef-bach/issues/847
  # We know the first run might fail set +e
  set +e
  vagrant ssh bootstrap -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  set -e
  # if we still fail here we have some other issue
  vagrant ssh bootstrap -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT Bootstrap"
  printf "Running final C-A-R(s)"
fi

printf "#### Chef machine bcpc-vms with $CLUSTER_TYPE\n"
vagrant ssh bootstrap -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE"

# for Hadoop installs we need to re-run the headnodes once HDFS is up to ensure
# we deploy various JARs. Run a second time once a datanode is up.
if [[ "${CLUSTER_TYPE,,}" == "hadoop" ]]; then
  vagrant ssh bootstrap -c "cd chef-bcpc; ./cluster-assign-roles.sh $BACH_ENVIRONMENT $CLUSTER_TYPE BCPC-Hadoop-Head"
fi

printf '#### Install Completed!\n'
