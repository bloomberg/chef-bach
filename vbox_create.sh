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
  pushd $VBOX_DIR_PATH

  remove_DHCPservers

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
  vagrant up --provision
  popd
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
  # Gather VirtualBox networks in use by bootstrap VM
  oifs="$IFS"
  IFS=$'\n'
  bootstrap_interfaces=($($VBM showvminfo ${BOOTSTRAP_NAME} \
    --machinereadable | \
    egrep '^hostonlyadapter[0-9]=' | \
    sort | \
    sed -e 's/.*=//' -e 's/"//g'))
  IFS="$oifs"
  VBN0="${bootstrap_interfaces[0]?Need a Virtualbox network 1 for the bootstrap}"
  VBN1="${bootstrap_interfaces[1]?Need a Virtualbox network 2 for the bootstrap}"
  VBN2="${bootstrap_interfaces[2]?Need a Virtualbox network 3 for the bootstrap}"

  if [[ $CLUSTER_VM_EFI == true ]]; then
    #
    # Add the ipxe USB key to the vbox storage registry as an immutable
    # disk, so we can share it between several VMs.
    #
    current_ipxe=$(vboxmanage list hdds | egrep '^Location:.*ipxe.vdi$')
    # we have an ipxe disk added
    if [[ -n "$current_ipxe" ]]; then
      ipxe_location=$(echo "$current_ipxe" | sed 's/^Location:[ ]*//')
      # ensure the location is available -- if not blow it away and recreate
      if $VBM showmediuminfo "$ipxe_location" | egrep -q '^State:.*inaccessible'; then
        $VBM closemedium disk "$ipxe_location"
        # update if we changed ipxe_location to the local workspace
        ipxe_location="$VBOX_DIR_PATH/ipxe.vdi"
        create_vbox_ipxe_disk "$ipxe_location"
      fi
    else
      ipxe_location="$VBOX_DIR_PATH/ipxe.vdi"
      create_vbox_ipxe_disk "$ipxe_location"
    fi

    # provide the IPXE disk location so we know if it is from
    # another cluster
    echo "NOTE: Using IPXE volume at: $ipxe_location"
  fi

  # Create each VM
  for vm in ${VM_LIST[*]}; do
      # Only if VM doesn't exist
      if ! $VBM list vms | grep "^\"${vm}\"" ; then
          $VBM createvm --name $vm --ostype Ubuntu_64 \
	       --basefolder $VBOX_DIR_PATH --register

          $VBM modifyvm $vm --memory $CLUSTER_VM_MEM
          $VBM modifyvm $vm --cpus $CLUSTER_VM_CPUs

	  if [[ $CLUSTER_VM_EFI == true ]]; then
	      # Force UEFI firmware.
	      $VBM modifyvm $vm --firmware efi
	  fi

          # Add the network interfaces
          $VBM modifyvm $vm --nic1 hostonly --hostonlyadapter1 "$VBN0"
          $VBM modifyvm $vm --nic2 hostonly --hostonlyadapter2 "$VBN1"
          $VBM modifyvm $vm --nic3 hostonly --hostonlyadapter3 "$VBN2"

	  # Create a disk controller to hang disks off of.
	  DISK_CONTROLLER="SATA_Controller"
	  $VBM storagectl $vm --name $DISK_CONTROLLER --add sata

	  #
	  # Create the root disk, /dev/sda.
	  #
	  # (/dev/sda is hardcoded into the preseed file.)
	  #
	  port=0
	  DISK_PATH=$VBOX_DIR_PATH/$vm/$vm-a.vdi
	  $VBM createhd --filename $DISK_PATH \
	       --size $CLUSTER_VM_ROOT_DRIVE_SIZE
          $VBM storageattach $vm --storagectl $DISK_CONTROLLER \
	       --device 0 --port $port --type hdd --medium $DISK_PATH
	  port=$((port+1))

	  if [[ $CLUSTER_VM_EFI == true ]]; then
	      # Attach the iPXE boot medium as /dev/sdb.
              $VBM storageattach $vm --storagectl $DISK_CONTROLLER \
		   --device 0 --port $port --type hdd --medium $ipxe_location
	      port=$((port+1))
	  else
	      # If we're not using EFI, force the BIOS to boot net.
	      $VBM modifyvm $vm --boot1 net
	  fi

	  #
	  # Create our data disks
	  #
	  # For these to be used properly, we will need to override
	  # the attribute default[:bcpc][:hadoop][:disks] in a role or
	  # environment.
	  #
          for disk in c d e f; do
	      DISK_PATH=$VBOX_DIR_PATH/$vm/$vm-$disk.vdi
              $VBM createhd --filename $DISK_PATH \
		   --size $CLUSTER_VM_DRIVE_SIZE
              $VBM storageattach $vm --storagectl $DISK_CONTROLLER \
		   --device 0 --port $port --type hdd --medium $DISK_PATH
              port=$((port+1))
          done

          # Set hardware acceleration options
          $VBM modifyvm $vm \
	       --largepages on \
	       --vtxvpid on \
	       --hwvirtex on \
	       --nestedpaging on \
	       --ioapic on

          # Add serial ports
          $VBM modifyvm $vm --uart1 0x3F8 4
          $VBM modifyvm $vm --uartmode1 server /tmp/serial-${vm}-ttyS0
      fi
  done
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
