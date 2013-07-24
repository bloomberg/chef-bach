#!/bin/bash
#
# A simple tool to check the basics of our cluster - machines up, services running
# This tool uses the cluster hardware list file cluster.txt
# The first param specifies the environment
# For the second, optional param :
# - if no param is passed, all nodes are checked
# - if 'head' is passed only head nodes are checked
# - if 'work' is passed only work nodes are checked
#
# This may be helpful as a quick check after completing the knife
# bootstrap phase (assigning roles to nodes).
#
if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage $0 'environment' (role)"
    exit
fi
#set -x
ENVIRONMENT="$1"
ROLEWANTED="$2"
if [[ -f cluster.txt ]]; then
    while read HOSTNAME MACADDR IPADDR DOMAIN ROLE; do
	if [[ $HOSTNAME = "end" ]]; then
	    continue
	fi
	if [[ -z "$ROLEWANTED" || "$ROLEWANTED" = "$ROLE"  ]]; then
	    HOSTS="$HOSTS $HOSTNAME"
	fi
    done < cluster.txt
    echo "HOSTS = $HOSTS"

    for HOST in $HOSTS; do
	if [[ -z `fping -aq $HOST` ]]; then
	    echo $HOST is down
	else
	    echo $HOST is up
	    UP=$[UP + 1]
	fi
	if [[ -z `./nodessh.sh $ENVIRONMENT $HOST "ip route show table mgmt | grep default"` ]]; then
	    echo "$HOST no mgmt default route !!WARNING!!"
	else
	    echo "$HOST has a default mgmt route"
	    MG=$[MG + 1]
	fi
	if [[ -z `./nodessh.sh $ENVIRONMENT $HOST "ip route show table storage | grep default"` ]]; then
	    echo "$HOST has no storage default route !!WARNING!!"
	else
	    echo "$HOST has a default storage route"
	    SG=$[SG + 1]
	fi
	for SERVICE in keystone glance-api glance-registry cinder-scheduler cinder-volume cinder-api nova-api nova-novncproxy nova-scheduler nova-consoleauth nova-cert nova-conductor nova-compute nova-network; do
	    STAT=`./nodessh.sh $ENVIRONMENT $HOST "service $SERVICE status | grep running" sudo`
	    if [[ ! "$STAT" =~ "unrecognized" ]]; then
		STAT=`echo $STAT | cut -f2 -d":"`
		printf "%20s %s\n" "$SERVICE" "$STAT"
	    fi
	done
	STAT=`./nodessh.sh $ENVIRONMENT $HOST "ceph -s | grep HEALTH" sudo`
	STAT=`echo $STAT | cut -f2 -d":"`
	printf "%20s %s\n" ceph "$STAT"
	echo
    done
else
	echo "Warning 'cluster.txt' not found"
fi
echo "$ENVIRONMENT cluster summary: $UP hosts up. $MG hosts with default mgmt route. $SG hosts with default storage route"