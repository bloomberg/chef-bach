Overview
========

This is a set of Chef cookbooks to bring up an instance of an OpenStack-based
cluster of head and worker nodes.

Each head node runs all of the core services in a highly-available manner with
no restriction upon how many head nodes there are.  The cluster is deemed
operational as long as 50%+1 of the head nodes are online.  Otherwise, a
network partition may occur with a split-brain scenario.  In practice,
we currently recommend roughly one head node per rack.

Each worker node runs the relevant services (nova-compute, Ceph OSDs, etc.).
There is no limitation on the number of worker nodes.  In practice, we
currently recommend that the cluster should not grow to more than 200 worker
nodes.

Setup
=====

These cookbooks assume that you already have the following cookbooks
available:
 - apt
 - ubuntu
 - chef-client

These recipes are currently intended for an Ubuntu 12.04 image with four
storage devices (aside from boot volume) and three NICs.  You can modify
the environments accordingly for your setup.

You can install these cookbooks via:

 $ knife cookbook site download apt  
 $ knife cookbook site download ubuntu  
 $ knife cookbook site download chef-client  

You can set up the environment with:

 $ knife environment from file environments/*.json  
 $ knife role from file roles/*.json  
 $ knife cookbook upload -a

To enroll a machine as a head node:

 $ knife bootstrap -E Test-Laptop -r "role[BCPC-Headnode]" IP-address

To enroll a machine as a worker node:

 $ knife bootstrap -E Test-Laptop -r "role[BCPC-Worknode]" IP-address
