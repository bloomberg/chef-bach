#!/bin/bash
#
# A simple tool to check the basics of our cluster - machines up, services running
# This tool uses the cluster hardware list file cluster.txt
# - if no param is passed, all nodes are checked
# - if 'head' is passed only head nodes are checked
# - if 'work' is passed only work nodes are checked
#
# This may be helpful as a quick check after completing the knife
# bootstrap phase (assigning roles to nodes).
#
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
	else
	    echo $HOST is up
	    UP=$[UP + 1]
	fi
	if [[ -z `./nodessh.sh DNY1 $HOST "ip route show table mgmt | grep default"` ]]; then
	    echo "$HOST no mgmt default route !!WARNING!!"
	else
	    echo "$HOST has a default mgmt route"
	    MG=$[MG + 1]
	fi
	if [[ -z `./nodessh.sh DNY1 $HOST "ip route show table storage | grep default"` ]]; then
	    echo "$HOST has no storage default route !!WARNING!!"
	else
	    echo "$HOST has a default storage route"
	    SG=$[SG + 1]
	fi
	for SERVICE in keystone glance-api glance-registry cinder-scheduler cinder-volume cinder-api nova-api nova-novncproxy nova-scheduler nova-consoleauth nova-cert nova-conductor nova-compute nova-network; do
	    STAT=`./nodessh.sh DNY1 $HOST "service $SERVICE status | grep running" sudo`
	    if [[ ! "$STAT" =~ "unrecognized" ]]; then
		STAT=`echo $STAT | cut -f2 -d":"`
		printf "%20s %s\n" "$SERVICE" "$STAT"
	    fi
	done
	STAT=`./nodessh.sh DNY1 $HOST "ceph -s | grep HEALTH" sudo`
	STAT=`echo $STAT | cut -f2 -d":"`
	printf "%20s %s\n" ceph "$STAT"
	echo
    done
else
	echo "Warning 'cluster.txt' not found"
fi
echo "$UP hosts up. $MG hosts with default mgmt route. $SG hosts with default storage route"