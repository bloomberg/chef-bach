#!/bin/bash
#
# Script to help making a cluster definition file (cluster.txt) from
# the current VMs known by VirtualBox
#
# cluster.txt can be used by the cluster-*.sh tools for various
# cluster automation tasks, see cluster-readme.txt
#

if [[ -z "$1" ]]; then
	echo "Usage: $0 domain"
fi

DOMAIN=$1

VBM=VBoxManage

function getvminfo {
	# extract the first mac address for this VM
	MAC1=`$VBM showvminfo $1 | grep "NIC 1" | grep MAC | awk '{print $4}' | awk '{print substr($0, 1, length() -1)}'`
	# add the customary colons in
	MAC1=`echo $MAC1 | sed -e 's/^\([0-9A-Fa-f]\{2\}\)/\1_/'  \
     -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
     -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
     -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
     -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
     -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1/'`
	# now get the IP address
	IP=`VBoxManage guestproperty get $1 "/VirtualBox/GuestInfo/Net/0/V4/IP" | awk '{print $2}'`
	echo "$1 $MAC1 $IP $DOMAIN unknown"
}

if [[ -f cluster.txt ]]; then
	echo "Found cluster.txt. Saved as cluster.txt.save$$"
	mv cluster.txt cluster.txt.save$$
	touch cluster.txt
fi

VMLIST=`$VBM list vms`
for V in $VMLIST; do
	if [[ ! "$V" =~ "{" ]]; then
		VM=`echo "$V" | awk '{print substr($0, 2, length() -2)}'`
		getvminfo $VM >> cluster.txt
	fi
done
echo "end" >> cluster.txt
echo "cluster.txt created. Please assign roles"