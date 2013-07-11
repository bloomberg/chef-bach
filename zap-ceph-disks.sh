#!/bin/bash
#
# Script to reinitialise real disks on BCPC DNY cluster where disks b
# ... h are given over to Ceph
#
# location of sgdisk
TOOLPATH=/sbin
# name of sgdisk binary
DISKCOMMAND=sgdisk
# what to invoke sgdisk with
ZAPFLAGS="-Zog"
GUARDFILE=/etc/ceph-disks-zapped

if dpkg -s gdisk 2>/dev/null | grep -q Status.*installed; then
    echo "gdisk is installed"
else
    echo "install gdisk..."
    apt-get install --allow-unauthenticated -y gdisk
fi

if [[ -z `which $DISKCOMMAND` ]]; then
    echo "can't find '$DISKCOMMAND'"
    exit
fi

if [[ ! -f $GUARDFILE ]]; then
    for DISK in b c d e f g h; do
	COMMAND="$TOOLPATH/$DISKCOMMAND $ZAPFLAGS /dev/sd$DISK"
	echo $COMMAND
	$COMMAND
    done
else
    echo "disks look zapped already"
fi
touch /etc/ceph-disks-zapped