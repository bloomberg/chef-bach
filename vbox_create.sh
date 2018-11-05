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

# Is this a Hadoop or Kafka cluster?
# (Kafka clusters, being 6 nodes, will require more RAM.)
export CLUSTER_TYPE=${CLUSTER_TYPE:-Hadoop}

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

# The root drive on cluster nodes must allow for a RAM-sized swap volume.
CLUSTER_VM_ROOT_DRIVE_SIZE=$((CLUSTER_VM_DRIVE_SIZE + CLUSTER_VM_MEM - 2048))

VBOX_DIR="`dirname ${BASH_SOURCE[0]}`/vbox"
[[ -d $VBOX_DIR ]] || mkdir $VBOX_DIR
VBOX_DIR_PATH=`python -c "import os.path; print os.path.abspath(\"${VBOX_DIR}/\")"`

# Populate the VM list array from cluster.txt
code_to_produce_vm_list="
require './lib/cluster_data.rb';
include BACH::ClusterData;
cp=ENV.fetch('BACH_CLUSTER_PREFIX', '');
cp += '-' unless cp.empty?;
vms = parse_cluster_txt(File.readlines('cluster.txt'))
puts vms.map{|e| cp + e[:hostname]}.join(' ')
"
export VM_LIST=( $(/usr/bin/env ruby -e "$code_to_produce_vm_list") )

######################################################
# Function to download files necessary for VM stand-up
#
function download_VM_files {
  pushd $VBOX_DIR_PATH

  # Grab the Ubuntu 14.04 installer image
  if [[ ! -f ubuntu-14.04-mini.iso ]]; then
     $CURL -o ubuntu-14.04-mini.iso http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/trusty-netboot/mini.iso
  fi

  # Can we create the bootstrap VM via Vagrant
  if [[ ! -f trusty-server-cloudimg-amd64-vagrant-disk1.box ]]; then
    $CURL -o trusty-server-cloudimg-amd64-vagrant-disk1.box http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box
  fi
  popd
}

################################################################################
# Function to snapshot VirtualBox VMs
# Argument: name of snapshot to take
# Post-Condition: If snapshot did not previously exist for VM: VM snapshot taken
#                 If snapshot previously exists for that VM: Nothing for that VM
function snapshotVMs {
  local snapshot_name="$1"
  printf "Snapshotting ${snapshot_name}\n"
  for vm in ${VM_LIST[*]} ${BOOTSTRAP_NAME}; do
    $VBM snapshot $vm list --machinereadable | grep -q "^SnapshotName=\"${snapshot_name}\"\$" || \
      $VBM snapshot $vm take "${snapshot_name}" &
  done
  wait && printf "Done Snapshotting\n"
}

################################################################################
# Function to enumerate VirtualBox hostonly interfaces
# in use from VM's.
# Argument: name of an associative array defined in calling context
# Post-Condition: Updates associative array provided by name with keys being
#                 all interfaces in use and values being the number of VMs on
#                 each network
function discover_VBOX_hostonly_ifs {
  # make used_ifs a typeref to the passed-in associative array
  local -n used_ifs=$1
  for net in $($VBM list hostonlyifs | grep '^Name:' | sed 's/^Name:[ ]*//'); do
    used_ifs[$net]=0
  done
  for vm in $($VBM list vms | sed -e 's/^[^{]*{//' -e 's/}$//'); do
    ifs=$($VBM showvminfo --machinereadable $vm | \
      egrep '^hostonlyadapter[0-9]*' | \
      sed -e 's/^hostonlyadapter[0-9]*="//' -e 's/"$//')
    for interface in $ifs; do
      used_ifs[$interface]=$((${used_ifs[$interface]} + 1))
    done
  done
}

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
# Function to create the bootstrap VM
#
function create_bootstrap_VM {
  if [[ -f ../Vagrantfile.local.rb ]]; then
      cp ../Vagrantfile.local.rb .
  fi

  vagrant up bootstrap
}


###################################################################
# Function to create the ipxe disk
# Args: Location to use for the ipxe disk
# Post-Condition: The ipxe disk is added as a hdd in virtualbox
#
function create_vbox_ipxe_disk {
  cp files/default/ipxe.vdi $1
  $VBM modifyhd -type immutable $1
}

###################################################################
# Function to create the BCPC cluster VMs
#
function create_cluster_VMs {
  # FIXME clean this up
  vagrant up node0 node1 node2 node3 node4 node5
  # update cluster.txt to match VirtualBox MAC's
  ./vm-to-cluster.sh
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
  #vagrant ssh -c "sudo ucf -p /etc/default/grub"
  #vagrant ssh -c "sudo ucfr -p grub-pc /etc/default/grub"
  vagrant ssh -c "test -f /etc/default/grub.ucf-dist && sudo mv /etc/default/grub.ucf-dist /etc/default/grub" || true
  # Duplicate what d-i's apt-setup generators/50mirror does when set in preseed
  if [ -n "$http_proxy" ]; then
    proxy_found=true
    vagrant ssh -c "grep Acquire::http::Proxy /etc/apt/apt.conf" || proxy_found=false
    if [ $proxy_found == "false" ]; then
      vagrant ssh -c "echo 'Acquire::http::Proxy \"$http_proxy\";' | sudo tee -a /etc/apt/apt.conf"
    fi
  fi
  echo "Bootstrap complete - setting up Chef server"
  echo "N.B. This may take approximately 30-45 minutes to complete."
  vagrant ssh -c 'sudo rm -f /var/chef/cache/chef-stacktrace.out'
  ./bootstrap_chef.sh --vagrant-remote $ip $environment
  if vagrant ssh -c 'sudo grep -i no_lazy_load /var/chef/cache/chef-stacktrace.out'; then
      vagrant ssh -c 'sudo rm /var/chef/cache/chef-stacktrace.out' 
  elif vagrant ssh -c 'test -e /var/chef/cache/chef-stacktrace.out' || \
      ! vagrant ssh -c 'test -d /etc/chef-server'; then
    echo '========= Failed to Chef!' >&2
    exit 1
  fi
  vagrant ssh -c 'cd chef-bcpc; ./cluster-enroll-cobbler.sh remove' || true
  vagrant ssh -c 'cd chef-bcpc; ./cluster-enroll-cobbler.sh add'
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  download_VM_files
  create_bootstrap_VM
  create_cluster_VMs
  install_cluster
fi
