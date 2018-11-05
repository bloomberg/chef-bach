#!/bin/bash -e

# bash imports
source ./virtualbox_env.sh

set -x

if !hash ruby 2> /dev/null ; then
  echo 'No ruby in path!'
  exit 1
fi

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi
# CURL is exported by proxy_setup.sh
if [[ -z "$CURL" ]]; then
  echo 'CURL is not defined'
  exit 1
fi

# BOOTSTRAP_NAME is exported by automated_install.sh
if [[ -z "$BOOTSTRAP_NAME" ]]; then
  echo 'BOOTSTRAP_NAME is not defined'
  exit 1
fi

# Bootstrap VM Defaults (these need to be exported for Vagrant's Vagrantfile)
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM-2048}
export BOOTSTRAP_VM_CPUs=${BOOTSTRAP_VM_CPUs-1}
# Use this if you intend to make an apt-mirror in this VM (see the
# instructions on using an apt-mirror towards the end of bootstrap.md)
# -- Vagrant VMs do not use this size --
#BOOTSTRAP_VM_DRIVE_SIZE=120480

# Is this a Hadoop or Kafka cluster?
# (Kafka clusters, being 6 nodes, will require more RAM.)
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}

# Cluster VM Defaults
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM-2048}
export CLUSTER_VM_CPUs=${CLUSTER_VM_CPUs-1}
export CLUSTER_VM_EFI=${CLUSTER_VM_EFI:-true}
export CLUSTER_VM_DRIVE_SIZE=${CLUSTER_VM_DRIVE_SIZE-20480}

if !hash vagrant 2> /dev/null ; then
  echo 'Vagrant not detected - we need Vagrant!' >&2
  exit 1
fi

# Gather override_attribute bcpc/cluster_name or an empty string
environments=( ./environments/*.json )
if (( ${#environments[*]} > 1 )); then
  echo 'Need one and only one environment in environments/*.json; got: ' \
       "${environments[*]}" >&2
  exit 1
fi

VBOX_DIR="`dirname ${BASH_SOURCE[0]}`/vbox"
[[ -d $VBOX_DIR ]] || mkdir $VBOX_DIR
VBOX_DIR_PATH=`python -c "import os.path; print os.path.abspath(\"${VBOX_DIR}/\")"`

################################################################################
# Function to remove VirtualBox DHCP servers
# By default, checks for any DHCP server on networks without VM's & removes them
# (expecting if a remove fails the function should bail)
# If a network is provided, removes that network's DHCP server
# (or passes the vboxmanage error and return code up to the caller)
#
function remove_DHCPservers {
  local network_name=${1-}
  if [[ -z "$network_name" ]]; then
    local vms=$($VBM list vms|sed 's/^.*{\([0-9a-f-]*\)}/\1/')
    # will produce a list of networks like ^vboxnet0$|^vboxnet1$ which are in use by VMs
    local existing_nets_reg_ex=$(sed -e 's/^/^/' -e '/$/$/' -e 's/ /$|^/g' <<< $(for vm in $vms; do $VBM showvminfo --details --machinereadable $vm | grep -i 'adapter[2-9]=' | sed -e 's/^.*=//' -e 's/"//g'; done | sort -u))

    $VBM list dhcpservers | grep -E "^NetworkName:\s+HostInterfaceNetworking" | sed 's/^.*-//' |
    while read -r network_name; do
      [[ -n $existing_nets_reg_ex ]] && ! egrep -q $existing_nets_reg_ex <<< $network_name && continue
      remove_DHCPservers $network_name
    done
  else
    $VBM dhcpserver remove --ifname "$network_name" && local return=0 || local return=$?
    return $return
  fi
}

###################################################################
# Copy local configuration files into place from the legacy build.
#
function copy_local_configuration {
  pushd $VBOX_DIR_PATH

  #remove_DHCPservers

  echo "Vagrant detected - using Vagrant to initialize bcpc-bootstrap VM"
  cp ../Vagrantfile .

  if [[ -f ../Vagrantfile.local.rb ]]; then
      cp ../Vagrantfile.local.rb .
  fi

  if [[ ! -f insecure_private_key ]]; then
    # Ensure that the private key has been created by running vagrant at least once
    vagrant status
    cp $HOME/.vagrant.d/insecure_private_key .
  fi

  popd
}

###################################################################
# Function to create the BCPC cluster VMs
#
function create_cluster_VMs {
  pushd $VBOX_DIR_PATH
  vagrant up --provision --parallel
  popd

  # # update cluster.txt to match VirtualBox MAC's
  # ./vm-to-cluster.sh
}

###################################################################
# Function to setup the bootstrap VM
# Assumes cluster VMs are created
#
function install_cluster {
  environment=${1-Test-Laptop}
  ip=${2-10.0.100.3}
  # N.B. As of Aug 2013, grub-pc gets confused and wants to prompt re: 3-way
  # merge.  Sigh.
  #vagrant ssh bootstrap -c "sudo ucf -p /etc/default/grub"
  #vagrant ssh bootstrap -c "sudo ucfr -p grub-pc /etc/default/grub"
  vagrant ssh bootstrap -c "test -f /etc/default/grub.ucf-dist && sudo mv /etc/default/grub.ucf-dist /etc/default/grub" || true
  # Duplicate what d-i's apt-setup generators/50mirror does when set in preseed
  if [ -n "$http_proxy" ]; then
    proxy_found=true
    vagrant ssh bootstrap -c "grep Acquire::http::Proxy /etc/apt/apt.conf" || proxy_found=false
    if [ $proxy_found == "false" ]; then
      vagrant ssh bootstrap -c "echo 'Acquire::http::Proxy \"$http_proxy\";' | sudo tee -a /etc/apt/apt.conf"
    fi
  fi
  echo "Bootstrap complete - setting up Chef server"
  echo "N.B. This may take approximately 30-45 minutes to complete."
  vagrant ssh bootstrap -c 'sudo rm -f /var/chef/cache/chef-stacktrace.out'
  ./bootstrap_chef.sh --vagrant-remote $ip $environment
  if vagrant ssh bootstrap -c 'sudo grep -i no_lazy_load /var/chef/cache/chef-stacktrace.out'; then
      vagrant ssh bootstrap -c 'sudo rm /var/chef/cache/chef-stacktrace.out'
  elif vagrant ssh bootstrap -c 'test -e /var/chef/cache/chef-stacktrace.out' || \
      ! vagrant ssh bootstrap -c 'test -d /etc/chef-server'; then
    echo '========= Failed to Chef!' >&2
    exit 1
  fi
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  copy_local_configuration
  create_cluster_VMs
  install_cluster
fi
