#!/bin/bash
#
# nodessh.sh
#
# Convenience script for running commands over ssh to BCPC nodes when
# their cobbler root passwd is available in the chef databags. 
#
# Parameters:
# $1 is the name of chef environment file, without the .json file extension
# $2 is the IP address or name of the node on which to execute the specified command
# $3 is the command to execute (use "-" for an interactive shell)
# $4 (optional) if 'sudo' is specified, the command will be executed using sudo
#
if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    NAME=$(basename "$0")
    if [[ "$NAME" = nodescp ]]; then
        echo "Usage: $0 'environment' 'nodename|IP address' 'from' 'to'" > /dev/stderr
    else
        echo "Usage: $0 'environment' 'nodename|IP address' 'command' (sudo)" > /dev/stderr
    fi
    exit 2
fi

if [[ -z `which sshpass` ]]; then
    echo "Error: sshpass required for this tool. You should be able to 'sudo apt-get install sshpass' to get it" > /dev/stderr
    exit 1
fi

ENVIRONMENT=$1
NODE=$2
COMMAND=$3

# get the cobbler root passwd from the data bag
PASSWD=`knife data bag show configs $ENVIRONMENT 2>/dev/null | grep "cobbler-root-password:" | awk ' {print $2}'`
if [[ -z "$PASSWD" ]]; then
    echo "Failed to retrieve 'cobbler-root-password'; will try passwordless authentication" > /dev/stderr
else
    SSHPASS="sshpass -p $PASSWD"
fi

IP=$2

# check if the specified host is responding
if ! ping -W 2 -c 1 $IP >/dev/null 2>&1; then
    echo "Node $NODEFQDN($IP) doesn't appear to be on-line" > /dev/stderr
    exit 1
fi

SSHCOMMON="-q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o VerifyHostKeyDNS=no"

if [[ $(basename "$0") == nodescp ]]; then
    SCPCMD="scp $SSHCOMMON"
    $SSHPASS $SCPCMD -p "$3" "$4"
else
    # finally ... run the specified command
    # the -t creates a pty which ensures we see errors if the command fails

    SSHCMD="ssh $SSHCOMMON"

    if [[ "$4" == sudo ]]; then
        # if we need to sudo, pipe the passwd to that too
        if [ -n "$PASSWORD" ]; then
            sshpass -p $PASSWD $SSHCMD -t ubuntu@$IP "echo $PASSWD | sudo -S $COMMAND"
        else
            $SSHCMD -t ubuntu@$IP "sudo -S $COMMAND"
        fi
    else  
        # not sudo, do it the normal way
        if [[ "$COMMAND" == - ]]; then
            [ -n "$PASSWORD" ] && echo "You might need this : cobbler_root = $PASSWD"
            $SSHPASS $SSHCMD -t ubuntu@$IP
        else
            $SSHPASS $SSHCMD -t ubuntu@$IP "$COMMAND"
        fi
    fi
fi 

