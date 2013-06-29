#!/bin/bash
#
# nodessh.sh
#
# Convenience script for running commands over ssh to BCPC nodes when
# their cobbler root passwd is available in the chef databags. 
#
# If you pass an IP address, it will be used in the ssh command
# directly.  This is useful before nodes have been setup with chef -
# for example when performing pre-chef setup steps such as
# initialising disks
#
# If you pass a node name instead, the IP address is looked up in the
# data bags. This requires the target node to have been setup with
# chef already. This is useful for general-purpose cluster admin from
# the bootstrap node
#
#
# Parameters:
# $1 is the name of chef environment file, without the .json file extension
# $2 is the IP address or name of the node on which to execute the specified command
# $3 is the command to execute
# $4 (optional) if 'sudo' is specified, the command will be executed using sudo
#

#set -x
if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Usage: $0 'environment 'nodename|IP address' 'command' (sudo)"
    exit
fi
if [[ -z `which sshpass` ]]; then
    echo "Error: sshpass required for this tool"
    exit
fi

ENVIRONMENT=$1
NODE=$2
COMMAND=$3

# verify we can access the data bag for this environment
KNIFESTAT=`knife data bag show configs $ENVIRONMENT 2>&1 | grep ERROR`
if [[ ! -z "$KNIFESTAT" ]]; then
    echo "knife error $KNIFESTAT when showing the config"
    exit
fi

# get the cobbler root passwd from the data bag
PASSWD=`knife data bag show configs $ENVIRONMENT | grep "cobbler-root-password:" | awk ' {print $2}'`
if [[ -z "$PASSWD" ]]; then
    echo "Failed to retrieve 'cobbler-root-password'"
    exit
fi

# try to guess if the second param is an IP address
ISIP=`echo $2 | awk -F"\." ' $1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255 '`
if [[ ! -z "$ISIP" ]]; then
    # looks like an IP address
    IP=$ISIP
else 
    # assume it's a node name, get the IP from chef

    # check the environment
    KNIFESTAT=`knife environment show $ENVIRONMENT 2>&1 | grep ERROR`
    if [[ ! -z "$KNIFESTAT" ]]; then
	echo "Error: chef environment '$ENVIRONMENT' not found"
	exit
    fi

    # check the node list
    KNIFESTAT=`knife node list 2>&1| grep ERROR`
    if [[ ! -z "$KNIFESTAT" ]]; then
	echo "knife error $KNIFESTAT when listing the node"
	exit
    fi

    # convert the node name to a FQDN
    NODEFQDN=`knife node list | grep $NODE`
    if [[ -z "$NODEFQDN" ]]; then
	echo "Error: node '$NODE' not found"
	exit
    fi

    # verify that the FQDN can be found in the data bag
    KNIFESTAT=`knife node show $NODEFQDN | grep FATAL`
    if [[ ! -z "$KNIFESTAT" ]]; then
	echo "knife error $KNIFESTAT getting the node FQDN"
	exit
    fi

    # get the IP address for this node
    IP=`knife node show $NODEFQDN | grep IP: | awk ' {print $2}'`
fi

# check if the specified host is responding
UP=`ping -c 1 $IP | grep ttl`
if [[ -z "$UP" ]]; then
    echo "Node $NODEFQDN($IP) doesn't appear to be on-line"
    exit
fi

# finally ... run the specified command
# the -t creates a pty which ensures we see errors if the command fails
if [[ "$4" == sudo ]]; then
    # if we need to sudo, pipe the passwd to that too
    sshpass -p $PASSWD ssh -t ubuntu@$IP "echo $PASSWD | sudo -S $COMMAND"
else
    # not sudo, do it the normal way
    sshpass -p $PASSWD ssh -t ubuntu@$IP "$COMMAND"
fi