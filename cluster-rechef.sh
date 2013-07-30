#!/bin/bash
#
# Script to instruct all cluster nodes to rerun chef client - useful,
# for example, after changing chef recipes on the chef server.
#
# This script uses cluster.txt to find cluster node definitions, see
# cluster-readme.txt for details
#
#set -x
if [[ -z "$1" ]]; then
   echo "Usage: $0 environment"
fi
if [[ -f cluster.txt ]]; then
    while read HOSTNAME MACADDR IPADDR DOMAIN ROLE; do
	if [[ $HOSTNAME = "end" ]]; then
	    continue
	fi
	if [[ -z "$1" || "$1" = "$ROLE"  ]]; then
	    HOSTS="$HOSTS $HOSTNAME"
	fi
    done < cluster.txt
    echo "HOSTS = $HOSTS"
    for HOST in $HOSTS; do
	if [[ -z `fping -aq $HOST` ]]; then
	    echo $HOST is down
	    continue
	else
	    echo $HOST is up
	fi
	./nodessh.sh $1 $HOST "chef-client" sudo
    done
fi
