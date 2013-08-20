#!/bin/bash
#
# A simple tool to check the basics of our cluster - machines up, services running
# This tool uses the cluster hardware list file cluster.txt
#
# The first param specifies the environment
#
# For the second, optional param :
# - if no param is passed, or 'all', all nodes are checked
# - if 'head' is passed only head nodes are checked
# - if 'work' is passed only work nodes are checked
# - if an IP address or hostname is passed, just that node is checked
# 
# If any third param is passed, output is verbose, otherwise only
# output considered an exception is passed. You have to provide a 2nd
# param to allow a 3rd param to be recognized as simple positional
# param processing is used
#
# This may be helpful as a quick check after completing the knife
# bootstrap phase (assigning roles to nodes).
#
if [[ -z "$1" ]]; then
    echo "Usage $0 'environment' [role|IP] [verbose]"
    exit
fi
if [[ -z `which fping` ]]; then
    echo "This tool uses fping. You should be able to install fpring with `sudo apt-get install fping`"
    exit
fi
#set -x
ENVIRONMENT="$1"
HOSTWANTED="$2"
VERBOSE="$3"
# verbose trace - information that's not normally needed
function vtrace {
    if [[ ! -z "$VERBOSE" ]]; then
		for STR in "$@"; do
			echo $STR
		done
    fi
}
if [[ -f cluster.txt ]]; then
    while read HOSTNAME MACADDR IPADDR ILOIPADDR DOMAIN ROLE; do
		if [[ $HOSTNAME = "end" ]]; then
			continue
		fi
		if [[ -z "$HOSTWANTED" || "$HOSTWANTED" = all || "$HOSTWANTED" = "$ROLE" || "$HOSTWANTED" = "$IPADDR" || "$HOSTWANTED" = "$HOSTNAME" ]]; then
#	    HOSTS="$HOSTS $HOSTNAME"
			HOSTS="$HOSTS $IPADDR"
		fi
    done < cluster.txt
    vtrace "HOSTS = $HOSTS"
	
    for HOST in $HOSTS; do
		if [[ -z `fping -aq $HOST` ]]; then
			echo $HOST is down
			continue
		else
			vtrace "$HOST is up"
			UP=$[UP + 1]
		fi
		if [[ -z `./nodessh.sh $ENVIRONMENT $HOST "ip route show table mgmt | grep default"` ]]; then
			echo "$HOST no mgmt default route !!WARNING!!"
		else
			vtrace "$HOST has a default mgmt route"
			MG=$[MG + 1]
		fi
		if [[ -z `./nodessh.sh $ENVIRONMENT $HOST "ip route show table storage | grep default"` ]]; then
			echo "$HOST has no storage default route !!WARNING!!"
		else
			vtrace "$HOST has a default storage route"
			SG=$[SG + 1]
		fi
		CHEF=`./nodessh.sh $ENVIRONMENT $HOST "which chef-client"`
		if [[ -z "$CHEF" ]]; then
			echo "$HOST doesn't seem to have chef installed so probably hasn't been assigned a role"
			echo
			continue
		fi
		for SERVICE in keystone glance-api glance-registry cinder-scheduler cinder-volume cinder-api nova-api nova-novncproxy nova-scheduler nova-consoleauth nova-cert nova-conductor nova-compute nova-network haproxy; do
			STAT=`./nodessh.sh $ENVIRONMENT $HOST "service $SERVICE status | grep running" sudo`
			if [[ ! "$STAT" =~ "unrecognized" ]]; then
				STAT=`echo $STAT | cut -f2 -d":"`
				if [[ ! "$STAT" =~ "start/running" ]]; then
					printf "$HOST %20s %s\n" "$SERVICE" "$STAT"
				else
		    # couldn't get a "verbose printf" function to work
					if [[ ! -z "$VERBOSE" ]]; then
						printf "$HOST %20s %s\n" "$SERVICE" "$STAT"
					fi
				fi
			fi
		done
		STAT=`./nodessh.sh $ENVIRONMENT $HOST "ceph -s | grep HEALTH" sudo`
		STAT=`echo $STAT | cut -f2 -d":"`
		printf "$HOST %20s %s\n" ceph "$STAT"
		echo
    done
else
	echo "Warning 'cluster.txt' not found"
fi
echo "$ENVIRONMENT cluster summary: $UP hosts up. $MG hosts with default mgmt route. $SG hosts with default storage route"
