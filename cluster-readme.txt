cluster tools

chef-bcpc now includes some sample tools for helping install to real
hardware. 

Cluster definition file : cluster.txt

  Defines your hardware (see the sample file provided for an
  example). You can use vm-to-cluster.sh on the hypervisor to make a
  cluster.txt from your running VMs after booting.

  The expected fields are :

  nodeid hostname mac-address IP-address ILO-IP-Address Cobbler-Profile domain role
  
  numeric nodeid is only required for nodes with BCPC-Hadoop-Head role asigned
  For numeric id range is 1 through 255 
  For BCPC-Hadoop-Worker machines use `-` in the ID field  

  "ILO" stands for Integrated Lights-Out - a management console.
  It's not important for VMs.

Cluster helper scripts

  The following cluster-*.sh scripts use simple wrappers for ssh and
  scp called "nodessh.sh" and "nodescp" which look up the node
  passwords from the knife data bags for your environment. See the
  'ssh, scp wrappers' section at the end of this file for more
  information on this.

cluster-assign-roles.sh

  Using cluster.txt, this tool assigns roles to nodes using Chef. This script
  is also the best way to ensure a node is re-Chefed with its correct role as
  certain operations (e.g. 'chef-client -o [...]') will change a nodes role.

ssh, scp wrappers

  The cluster tools rely on the standard tools 'sshpass' and (in many
  cases) 'fping' both of which you should be able to install using
  apt-get. The cluster tools also use nodessh.sh and
  nodescp. nodessh.sh is a simple ssh wrapper that automates looking
  up the encrypted passwords for your environment from the knife data
  bags and then passes it through using sshpass reducing the number of
  times you must supply the sudo passwd. nodescp is a symlink to
  nodessh.sh which is used similarly to scp but leverages the same ssh
  wrapping. 

  examples :

#
# perform a privileged operation  
#
ubuntu@bcpc-bootstrap:~/chef-bcpc$ ./nodessh.sh Test-Laptop 10.0.100.11 "service ufw restart" sudo
[sudo] password for ubuntu: ufw stop/waiting
ufw start/running
ubuntu@bcpc-bootstrap:~/chef-bcpc$ 

#
# log in interactively
#
$ ./nodessh.sh Test-Laptop 10.0.100.11 -
ubuntu@bcpc-bootstrap:~/chef-bcpc$ ./nodessh.sh Test-Laptop 10.0.100.11 -
Welcome to Ubuntu 12.04.2 LTS (GNU/Linux 3.2.0-51-generic x86_64)

 * Documentation:  https://help.ubuntu.com/
Last login: Tue Jul 30 13:49:55 2013 from 10.0.100.1
ubuntu@bcpc-vm1:~$ uptime
 14:11:30 up  1:34,  1 user,  load average: 0.00, 0.01, 0.05
ubuntu@bcpc-vm1:~$ exit
logout
ubuntu@bcpc-bootstrap:~/chef-bcpc$ 

#
# use of nodescp
#
ubuntu@bcpc-bootstrap:~/chef-bcpc$ echo test > somefile.txt
ubuntu@bcpc-bootstrap:~/chef-bcpc$ ./nodescp Test-Laptop 10.0.100.11 somefile.txt ubuntu@10.0.100.11:/home/ubuntu
ubuntu@bcpc-bootstrap:~/chef-bcpc$ ./nodessh.sh Test-Laptop 10.0.100.11 'more somefile.txt'
test
ubuntu@bcpc-bootstrap:~/chef-bcpc$ 
