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

cluster-check.sh

  Checks nodes list in cluster.txt for being up, having default routes
  on the storage and management networks and running well-known
  services. Pass a role to limit the checks to machines in that
  role. Useful after bringing up a cluster to verify the basic health
  of all nodes.

cluster-vip.sh

  Using your environment file, this tool finds the current VIP
  (virtual IP) on your cluster so you can connect to its services or
  log onto that physical node for maintenance or troubleshooting.
