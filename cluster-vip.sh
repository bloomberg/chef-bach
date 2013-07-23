#!/bin/bash
if [[ -z "$1" ]]; then
	if [[ -d environments ]]; then
		ENVIRONMENTS=`echo environments/*.json | wc -l`
	fi
	if (($ENVIRONMENTS == 1)); then
		VIP=`grep -i vip environments/*.json | awk '{print $3}' | awk '{print substr($0, 2, length() - 3)}'`
		echo "VIP from environment = $VIP"
	else
		echo "Usage: VIP not specified and more than one environment file found"
		exit
	fi
else 
    echo "VIP IP address set to $1"
    VIP="$1"
fi
if [[ ! -z `which fping` ]]; then
    # fping fails faster than ping
    UP=`fping -aq $VIP | awk '{print $1}'`
else
    UP=`ping -c1 $VIP | grep ttl | awk '{print $4}'`
fi
if [[ ! -z "$UP" ]]; then
    MAC=`arp -n $VIP | grep ether | awk '{print $3}'`
    HOST=`grep "$MAC" cluster.txt`
    echo "VIP is currently : $HOST"
else
    echo "$VIP appears to be down"
fi
