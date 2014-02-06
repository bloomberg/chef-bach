#!/bin/bash
# Script to assign roles to cluster nodes based on a definition in cluster.txt:
#
# - The environment is needed to find the root password of the machines
#   and to provide the environment in which to chef them
#
# - An install_type is needed; options are OpenStack or Hadoop
#
# - If no hostname is provided, all nodes will be attempted
#
# - if a nodename is provided, either by hostname or ip address, only
#   that node will be attempted
#
# - if a chef object is provided, e.g. role[ROLE-NAME] or
#   recipe[RECIPE-NAME], only nodes marked for that action are attempted
#
# - A node may be excluded by setting its action to SKIP

set -e
set -x
set -o nounset

########################################################################
# install_machines -  Install a set of machines (will run chefit.sh if no node object for machine)
# Argument: $1 - a string of role!IP!FQDN pairs separated by white space
# Will install the machine with role $role
function install_machines {
  passwd=`knife data bag show configs $ENVIRONMENT | grep "cobbler-root-password:" | awk ' {print $2}'`
  for h in $(sort <<< ${*// /\\n}); do
    local regEx='(.*)!(.*)!.*'
    [[ "$h" =~ $regEx ]]
    local run_list="${BASH_REMATCH[1]}"
    local ip="${BASH_REMATCH[2]}"
    printf "About to bootstrap node $ip to $ENVIRONMENT ${run_list}...\n"
    knife node show $fqdn 2>/dev/null >/dev/null || ./chefit.sh $ip $ENVIRONMENT
    local SSHCMD="./nodessh.sh $ENVIRONMENT $ip"
    sudo knife bootstrap -E $ENVIRONMENT -r "$run_list" $ip -x ubuntu  -P $passwd -u admin -k /etc/chef-server/admin.pem --sudo <<< $passwd
  done
}

#############################################################################################
# parse cluster.txt 
# Argument: $1 - optional case insensitive match text (e.g. hostname, ipaddress, chef object)
# Returns: List of matching hosts (or all non-skipped hosts) one host per line with ! delimited fileds
# (Note: if you want to skip a machine, set its role to SKIP in cluster.txt)
function parse_cluster_txt {
  local match_text=${1-}
  local hosts=""
  while read host macaddr ipaddr iloipaddr domain role; do
    shopt -s nocasematch
    if [[ -z "${match_text-}" || "$match_text" = "$host" || "$match_text" = "$ipaddr" || "$match_text" = "$role" ]] && \
       [[ ! "|$role" =~ '|SKIP' ]]; then
      hosts="$hosts ${role}!${ipaddr}!${host}.$domain"
    fi
    shopt -u nocasematch
  done < cluster.txt
  printf "$hosts"
}
# Global Regular Expression for parsing parse_cluster_txt output
REGEX='(.*)!(.*)!(.*)'

##########################################
# Install Machine Stub
# Function to create basic machine representation (in parallel) if Chef does not
# already know about machine
# Runs: Chef role[Basic], Chef recipe[bcpc::default], recipe[bcpc::networking]
# Argument: $* - hosts are returned by parse_cluster_txt
function install_stub {
  printf "Creating stubs for nodes...\n"
  for h in $*; do
    [[ "$h" =~ $REGEX ]]
    local role="${BASH_REMATCH[1]}"
    local ip="${BASH_REMATCH[2]}"
    local fqdn="${BASH_REMATCH[3]}"
    knife node show $fqdn 2>/dev/null >/dev/null ||  install_machines "role[Basic],recipe[bcpc::default],recipe[bcpc::networking]!$ip!NONE" &
  done
  wait
}

########################################################################
# Perform OpenStack install
# Arguments: $* - hosts (as output from parse_cluster_txt)
# Runs the end-to-end install in the proper order for OpenStack installs
# Install method:
# First, install first headnode -- which needs to be an admin
# Next, install head-nodes start to finish and back to start synchronously
# (this ensures all headnodes know of eachother)
# Lastly, install workers in parallel)
function openstack_install {
  local hosts="$*"
  local err_trap="$(trap ERR)"
  trap '$err_trap; echo -e "####\n#### Failed installing $host\n####"' ERR
  shopt -u nocasematch
  printf "Doing OpenStack style install...\n"

  [[ "$(printf ${hosts// /\\n} | grep -i "head" | sort | head -1)" =~ $REGEX ]] && first_head_node="${BASH_REMATCH[3]}" || \
    (printf "Failed to parse hosts\n"; exit 1 )
  install_stub $first_head_node
  # set the first node to admin for creating data bags (short-circuit failures in-case machine already is an admin)
  printf "/\"admin\": false\ns/false/true\nw\nq\n" | EDITOR=ed knife client edit $first_head_node || /bin/true

  # Do head nodes first and group by type of head
  printf "Installing heads...\n"
  install_machines $(printf ${hosts// /\\n} | grep -i "head" | sort)
  # Redo head nodes in reverse order to ensure they know about eachother
  # (the last node already knows everyone in the universe of heads)
  printf "Acquainting heads...\n"
  install_machines $(printf ${hosts// /\\n} | grep -i "head" | sort | head -n -1 | tac)
  # Do everything else next and group by type of node
  printf "Installing workers...\n"
  for m in $(printf ${hosts// /\\n} | grep -vi "head" | sort); do
    ( install_machines $m || exit 1 )&
  done
  wait
  trap "$err_trap" ERR
}

########################################################################
# Perform Hadoop install
# Arguments: $* - hosts (as output from parse_cluster_txt)
# Method:
# * Installs stubs (create chef nodes and setup networking) for all machines in parallel
# * Set all headnode to admins
# * Assigns roles for headnodes
# * Installs headnodes sorted by role
# * Unsets all headnode from being admins
# * Installs worknodes in parallel
function hadoop_install {
  local hosts="$*"
  shopt -u nocasematch
  printf "Doing Hadoop style install...\n"
  # to prevent needing to re-chef headnodes the Hadoop code base assumes
  # all nodes and clients have been created and further that all roles
  # have been assigned before any node Chefing begins
  install_stub $(printf ${hosts// /\\n} | sort)

  printf "Assigning roles for headnodes...\n"
  for h in $(printf ${hosts// /\\n} | grep -i "head" | sort); do
    [[ "$h" =~ $REGEX ]]
    local role="${BASH_REMATCH[1]}"
    local ip="${BASH_REMATCH[2]}"
    local fqdn="${BASH_REMATCH[3]}"
    knife node run_list add $fqdn "$role" &
  done

  # set the headnodes to admin for creating data bags
  for h in $(printf ${hosts// /\\n} | grep -i "head" | sort); do
    [[ "$h" =~ $REGEX ]]
    printf "/\"admin\": false\ns/false/true\nw\nq\n" | EDITOR=ed knife client edit "${BASH_REMATCH[3]}" || /bin/true
  done

  printf "Installing heads...\n"
  install_machines $(printf ${hosts// /\\n} | grep -i "head" | sort)

  # remove admin from the headnodes
  for h in $(printf ${hosts// /\\n} | grep -i "head" | sort); do
    [[ "$h" =~ $REGEX ]]
    printf "/\"admin\": true\ns/true/false\nw\nq\n" | EDITOR=ed knife client edit "${BASH_REMATCH[3]}"
  done

  printf "Installing workers...\n"
  for m in $(printf ${hosts// /\\n} | grep -vi "head" | sort); do
    install_machines $m &
  done
}

############
# Main Below
#

if [[ "${#*}" -lt "2" ]]; then
  printf "Usage : $0 environment install_type (hostname)\n" > /dev/stderr
  exit 1
fi

ENVIRONMENT=$1
INSTALL_TYPE=$2
MATCHKEY=${3-}

shopt -s nocasematch
if [[ ! "$INSTALL_TYPE" =~ (openstack|hadoop) ]]; then
  printf "Error: Need install type of OpenStack or Hadoop\n" > /dev/stderr
  exit 1
fi
shopt -u nocasematch

if [[ ! -f "environments/$ENVIRONMENT.json" ]]; then
  printf "Error: Couldn't find '$ENVIRONMENT.json'. Did you forget to pass the environment as first param?\n" > /dev/stderr
  exit 1
fi

# Report which hosts were found
hosts="$(parse_cluster_txt $MATCHKEY)"
for h in $hosts; do
  [[ "$h" =~ $REGEX ]]
  role="${BASH_REMATCH[1]}"
  ip="${BASH_REMATCH[2]}"
  fqdn="${BASH_REMATCH[3]}"
  printf "%s\t-\t%s\n" $role $fqdn
done | sort 

if [[ -z "${hosts-}" ]]; then
  printf "Warning: No nodes found\n" > /dev/stderr
  exit 0
fi

shopt -s nocasematch
if [[ "$INSTALL_TYPE" = "OpenStack" ]]; then
  openstack_install $hosts
### Hadoop Install Method
elif [[ "$INSTALL_TYPE" = "Hadoop" ]]; then
  hadoop_install $hosts
fi

printf "#### Install finished\n"
