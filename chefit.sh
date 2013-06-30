#!/bin/bash
set -x
./nodessh.sh Test-Laptop 10.0.100.12 "echo \"deb http://apt.opscode.com/ precise-0.10 main\" > /tmp/opscode.list" 
./nodessh.sh Test-Laptop 10.0.100.12 "cp /tmp/opscode.list /etc/apt/sources.list.d" sudo
./nodessh.sh Test-Laptop 10.0.100.12 "sudo apt-get update" sudo
./nodessh.sh Test-Laptop 10.0.100.12 "sudo apt-get install --allow-unauthenticated -y opscode-keyring" sudo
./nodessh.sh Test-Laptop 10.0.100.12 "sudo apt-get update" sudo
./nodessh.sh Test-Laptop 10.0.100.12 "DEBCONF_DB_FALLBACK=File{$(pwd)/debconf-chef.conf} DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install chef" sudo
./nodessh.sh Test-Laptop 10.0.100.12 "DEBCONF_DB_FALLBACK=File{$(pwd)/debconf-chef.conf} DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install chef-client" sudo
