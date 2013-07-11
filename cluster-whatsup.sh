#!/bin/bash
# a script to find which nodes, defined in a cluster definition file
# cluster.txt are responding to ping
if [[ -f cluster.txt ]]; then
    # fping is fast but might not be available
    if [[ -z `which fping` ]]; then
	# use standard ping instead
	while read HOSTNAME MACADDR IPADDR DOMAIN ROLE; do
	    if [[ ! "$HOSTNAME" = end ]]; then
		echo "scanning $ROLE node $HOSTNAME($IPADDR) using ping" && ping -c 1 $IPADDR | grep ttl |cut -f4 -d" " | cut -f1 -d":"
	    fi
	done < cluster.txt
	echo "Done"
    else
	# we can use fping
	while read HOSTNAME MACADDR IPADDR DOMAIN ROLE; do
	    ALLHOSTS="$ALLHOSTS $IPADDR"
	done < cluster.txt
	echo "scanning all hosts using fping..."
	UP=`fping -aq $ALLHOSTS 2> /dev/null`
	for H in $UP; do
	    echo $H
	done
    fi
else
    echo "Warning : no cluster definition (cluster.txt) found"
fi