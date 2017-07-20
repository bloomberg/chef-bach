#!/bin/bash -e

# bash imports
source ./virtualbox_env.sh

if [[ "$OSTYPE" == msys || "$OSTYPE" == cygwin ]]; then
  WIN=TRUE
fi

set -x

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi
if [[ -z "$CURL" ]]; then
  echo "CURL is not defined"
  exit
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
export CLUSTER_VM_EFI=${CLUSTER_VM_EFI:-false}
export CLUSTER_VM_DRIVE_SIZE=${CLUSTER_VM_DRIVE_SIZE-20480}

# The root drive on cluster nodes must allow for a RAM-sized swap volume.
CLUSTER_VM_ROOT_DRIVE_SIZE=$((CLUSTER_VM_DRIVE_SIZE + CLUSTER_VM_MEM - 2048))

VBOX_DIR="`dirname ${BASH_SOURCE[0]}`/vbox"
[[ -d $VBOX_DIR ]] || mkdir $VBOX_DIR
P=`python -c "import os.path; print os.path.abspath(\"${VBOX_DIR}/\")"`

if [ "$CLUSTER_TYPE" == "Kafka" ]; then
  VM_LIST=(bcpc-vm1 bcpc-vm2 bcpc-vm3 bcpc-vm4 bcpc-vm5 bcpc-vm6)
else
  VM_LIST=(bcpc-vm1 bcpc-vm2 bcpc-vm3)
fi

######################################################
# Function to download files necessary for VM stand-up
#
function download_VM_files {
  pushd $P

  # Grab the Ubuntu 14.04 installer image
  if [[ ! -f ubuntu-14.04-mini.iso ]]; then
     $CURL -o ubuntu-14.04-mini.iso http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/trusty-netboot/mini.iso
  fi

  # Can we create the bootstrap VM via Vagrant
  if hash vagrant ; then
    echo "Vagrant detected - downloading Vagrant box for bcpc-bootstrap VM"
    if [[ ! -f trusty-server-cloudimg-amd64-vagrant-disk1.box ]]; then
      $CURL -o trusty-server-cloudimg-amd64-vagrant-disk1.box http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box
    fi
  fi

  popd
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
    local vms=$(vboxmanage list vms|sed 's/^.*{\([0-9a-f-]*\)}/\1/')
    # will produce a list of networks like ^vboxnet0$|^vboxnet1$ which are in use by VMs
    local existing_nets_reg_ex=$(sed -e 's/^/^/' -e '/$/$/' -e 's/ /$|^/g' <<< $(for vm in $vms; do vboxmanage showvminfo --details --machinereadable $vm | grep -i 'adapter[2-9]=' | sed -e 's/^.*=//' -e 's/"//g'; done | sort -u))

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
# uses Vagrant or stands-up the VM in VirtualBox for manual install
#
function create_bootstrap_VM {
  pushd $P

  remove_DHCPservers

  if hash vagrant 2> /dev/null ; then
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
  else
    echo "Vagrant not detected - using raw VirtualBox for bcpc-bootstrap"
    if [[ -z "WIN" ]]; then
      # Make the three BCPC networks we'll need, but clear all nets and dhcpservers first
      for i in 0 1 2 3 4 5 6 7 8 9; do
        if [[ ! -z `$VBM list hostonlyifs | grep vboxnet$i | cut -f2 -d" "` ]]; then
          $VBM hostonlyif remove vboxnet$i || true
        fi
      done
    else
      # On Windows the first interface has no number
      # The second interface is #2
      # Remove in reverse to avoid substring matching issue
      for i in 10 9 8 7 6 5 4 3 2 1; do
        if [[ i -gt 1 ]]; then
          IF="VirtualBox Host-Only Ethernet Adapter #$i";
        else
          IF="VirtualBox Host-Only Ethernet Adapter";
        fi
        if [[ ! -z `$VBM list hostonlyifs | grep "$IF"` ]]; then
          $VBM hostonlyif remove "$IF"
        fi
      done
    fi

    $VBM hostonlyif create
    $VBM hostonlyif create
    $VBM hostonlyif create

    if [[ -z "$WIN" ]]; then
      remove_DHCPservers vboxnet0 || true
      remove_DHCPservers vboxnet1 || true
      remove_DHCPservers vboxnet2 || true
      # use variable names to refer to our three interfaces to disturb
      # the remaining code that refers to these as little as possible -
      # the names are compact on Unix :
      VBN0=vboxnet0
      VBN1=vboxnet1
      VBN2=vboxnet2
    else
      # However, the names are verbose on Windows :
      VBN0="VirtualBox Host-Only Ethernet Adapter"
      VBN1="VirtualBox Host-Only Ethernet Adapter #2"
      VBN2="VirtualBox Host-Only Ethernet Adapter #3"
    fi

    $VBM hostonlyif ipconfig "$VBN0" --ip 10.0.100.2    --netmask 255.255.255.0
    $VBM hostonlyif ipconfig "$VBN1" --ip 172.16.100.2  --netmask 255.255.255.0
    $VBM hostonlyif ipconfig "$VBN2" --ip 192.168.100.2 --netmask 255.255.255.0

    # Create bootstrap VM
    for vm in bcpc-bootstrap; do
      # Only if VM doesn't exist
      if ! $VBM list vms | grep "^\"${vm}\"" ; then
          $VBM createvm --name $vm --ostype Ubuntu_64 --basefolder $P --register
          $VBM modifyvm $vm --memory $BOOTSTRAP_VM_MEM
          $VBM modifyvm $vm --cpus $BOOTSTRAP_VM_CPUs
          $VBM storagectl $vm --name "SATA Controller" --add sata
          $VBM storagectl $vm --name "IDE Controller" --add ide
          # Create a number of hard disks
          port=0
          for disk in a; do
              $VBM createhd --filename $P/$vm/$vm-$disk.vdi --size ${BOOTSTRAP_VM_DRIVE_SIZE-20480}
              $VBM storageattach $vm --storagectl "SATA Controller" --device 0 --port $port --type hdd --medium $P/$vm/$vm-$disk.vdi
              port=$((port+1))
          done
          # Add the network interfaces
          $VBM modifyvm $vm --nic1 nat
          $VBM modifyvm $vm --nic2 hostonly --hostonlyadapter2 "$VBN0"
          $VBM modifyvm $vm --nic3 hostonly --hostonlyadapter3 "$VBN1"
          $VBM modifyvm $vm --nic4 hostonly --hostonlyadapter4 "$VBN2"
          # Add the bootable mini ISO for installing Ubuntu 14.04
          $VBM storageattach $vm --storagectl "IDE Controller" --device 0 --port 0 --type dvddrive --medium ubuntu-14.04-mini.iso
          $VBM modifyvm $vm --boot1 disk
          # Add serial ports
          $VBM modifyvm $vm --uart1 0x3F8 4
          $VBM modifyvm $vm --uartmode1 server /tmp/serial-${vm}-ttyS0
      fi
    done
  fi
  popd
}

###################################################################
# Function to create the BCPC cluster VMs
#
function create_cluster_VMs {
  # Gather VirtualBox networks in use by bootstrap VM
  oifs="$IFS"
  IFS=$'\n'
  bootstrap_interfaces=($($VBM showvminfo bcpc-bootstrap --machinereadable | \
				 egrep '^hostonlyadapter[0-9]=' | \
				 sort | \
				 sed -e 's/.*=//' -e 's/"//g'))
  IFS="$oifs"
  VBN0="${bootstrap_interfaces[0]}"
  VBN1="${bootstrap_interfaces[1]}"
  VBN2="${bootstrap_interfaces[2]}"

  #
  # Add the ipxe USB key to the vbox storage registry as an immutable
  # disk, so we can share it between several VMs.
  #
  IPXE_DISK=$P/ipxe.vdi
  cp files/default/ipxe.vdi $IPXE_DISK
  $VBM modifyhd -type immutable $IPXE_DISK

  # Create each VM
  for vm in ${VM_LIST[*]}; do
      # Only if VM doesn't exist
      if ! $VBM list vms | grep "^\"${vm}\"" ; then
          $VBM createvm --name $vm --ostype Ubuntu_64 \
	       --basefolder $P --register

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
	  DISK_PATH=$P/$vm/$vm-a.vdi
	  $VBM createhd --filename $DISK_PATH \
	       --size $CLUSTER_VM_ROOT_DRIVE_SIZE
          $VBM storageattach $vm --storagectl $DISK_CONTROLLER \
	       --device 0 --port $port --type hdd --medium $DISK_PATH
	  port=$((port+1))

	  if [[ $CLUSTER_VM_EFI == true ]]; then
	      # Attach the iPXE boot medium as /dev/sdb.
              $VBM storageattach $vm --storagectl $DISK_CONTROLLER \
		   --device 0 --port $port --type hdd --medium $IPXE_DISK
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
	      DISK_PATH=$P/$vm/$vm-$disk.vdi
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
}

function install_cluster {
environment=${1-Test-Laptop}
ip=${2-10.0.100.3}
  # VMs are now created - if we are using Vagrant, finish the install process.
  if hash vagrant ; then
    pushd $P
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
    popd
    echo "Bootstrap complete - setting up Chef server"
    echo "N.B. This may take approximately 30-45 minutes to complete."
    vagrant ssh -c 'sudo rm -f /var/chef/cache/chef-stacktrace.out'
    ./bootstrap_chef.sh --vagrant-remote $ip $environment
    if vagrant ssh -c 'test -e /var/chef/cache/chef-stacktrace.out' || \
        ! vagrant ssh -c 'test -d /etc/chef-server'; then
      echo '========= Failed to Chef!' >&2
      exit 1
    fi
    ./enroll_cobbler.sh
  fi
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  download_VM_files
  create_bootstrap_VM
  create_cluster_VMs
  install_cluster
fi
