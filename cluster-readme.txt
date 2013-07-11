cluster tools

chef-bcpc now includes some sample tools for helping install to real
hardware. 

cluster.txt

  Defines your hardware (see the sample file provided for an
  example). 

cluster-enroll-cobbler.sh

  Using cluster.txt, this tool enrolls or removes nodes from cobbler. 

cluster-assign-roles.sh

  Using cluster.txt, this tool assigns roles to node using chef.

cluster-whatsup.sh

  Finds out which nodes are responding on the network. Install fping
  to make this fast.
