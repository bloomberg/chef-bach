#!/bin/bash
#
# 
#
#set -x
IP="$1"
ENVIRONMENT="$2"
echo "initial configuration of $IP"

SCPCMD="./nodescp    $ENVIRONMENT $IP"
SSHCMD="./nodessh.sh $ENVIRONMENT $IP"

echo "copy files..."
$SCPCMD zap-ceph-disks.sh ubuntu@$IP:/home/ubuntu
$SCPCMD install-chef.sh   ubuntu@$IP:/home/ubuntu
$SCPCMD finish-worker.sh  ubuntu@$IP:/home/ubuntu
$SCPCMD finish-head.sh    ubuntu@$IP:/home/ubuntu

echo "setup chef"
$SSHCMD  "/home/ubuntu/install-chef.sh" sudo

echo "zap disks"
$SSHCMD "/home/ubuntu/zap-ceph-disks.sh" sudo

echo "temporarily adjust system time to avoid time skew related failures"
GOODDATE=`date`
$SSHCMD "date -s '$GOODDATE'" sudo

echo "done."

