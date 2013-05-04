Overview
========

This repository contains a set of scripts that is useful to bootstrap a BCPC
cluster with a Cobbler, Chef, DHCP, and gateway server.  Once the
bcpc-bootstrap node is created, all of the other nodes (such as bcpc-vm1,
bcpc-vm2, bcpc-vm3, etc.) can be PXE-booted with a valid image and then
chef-ified with minimal effort.

You are only required to bring up a bare Ubuntu 12.04 image before running the
bootstrap_chef.sh script - it will take the image the rest of the way
installing all of the good stuff.

To start off, create the VirtualBox images:

```
$ ./vbox_create.sh
```

This will create four VMs:
- bcpc-bootstrap (cobbler and chef server)
- bcpc-vm1
- bcpc-vm2
- bcpc-vm3

The bcpc-vm images will not work appropriately until the bcpc-bootstrap node is
configured and serving images via PXE.  Once this bootstrap process is
complete, they should automatically begin installation upon bootup.

Then, bring up the bcpc-bootstrap VM - which has a virtual CD attached to
kick off the Ubuntu install:

```
$ VBoxManage startvm bcpc-bootstrap
```

bcpc-bootstrap creation notes
=============================

If you have a base Ubuntu 12.04 image available through other means, you can
skip this step as long as you set up the appropriate interfaces and such.

Install notes:

- select eth3 as network interface for DHCP (vbox_create.sh sets it up as NAT)
- bcpc-bootstrap as hostname
- ubuntu/ubuntu as default user/password
- install grub to MBR
- remove virtual CD

Login to new VM.

If using NAT, port 22 inbound may be blocked; so, set up interface on eth0
hostonlyif.  Add to /etc/network/interfaces on bcpc-bootstrap:

```
auto eth0
iface eth0 inet static
  address 10.0.100.1
  netmask 255.255.255.0
```

After changing the interfaces file:

```
# service networking restart
```

This is a good time to take a snapshot of your bootstrap node:

```
$ VBoxManage snapshot bcpc-bootstrap take initial-install
```

bootstrap_chef.sh
=================

Once you can SSH in to the bcpc-bootstrap node (ssh ubuntu@10.0.100.1 if
following instructions above), you can then run the bootstrap_chef.sh script
from the hypervisor running VirtualBox:

```
$ ./bootstrap_chef.sh 10.0.100.1
```

- Chef server URL: http://10.0.100.1:4000
- Chef password: chef (must not be blank or chef-solr will not start)
- You can leave chef-server-webui pw blank (will default to admin/p@ssw0rd1)
  http://10.0.100.1:4040

Initial knife questions
=======================

You will be asked to set up your knife setup on the bcpc-bootstrap node.
The path to the chef repository must be . (period) to work.

```
Where should I put the config file? [/home/ubuntu/.chef/knife.rb] .chef/knife.rb
Please enter the chef server URL: [http://bcpc-bootstrap:4000] http://10.0.100.1:4000
Please enter a clientname for the new client: [ubuntu] 
Please enter the existing admin clientname: [chef-webui] 
Please enter the location of the existing admin client's private key: [/etc/chef/webui.pem] 
Please enter the validation clientname: [chef-validator] 
Please enter the location of the validation key: [/etc/chef/validation.pem] 
Please enter the path to a chef repository (or leave blank): .
```

You will eventually be prompted to make the initial client an admin - just
modify the admin flag to true and save the file.

Registering VMs for PXE boot
============================

If you use the bootstrap_chef.sh script, it will automatically register
bcpc-vm1, bcpc-vm2, and bcpc-vm3 VMs.  If you have other VMs to register:

```
cobbler system add --name=$i --hostname=$i --profile=bcpc_host --ip-address=10.0.100.20 --mac=AA:BB:CC:DD:EE:FF
```

Upon PXE boot imaging, the bcpc-vm boxes will be imaged with the auto-generated
password for the ubuntu user.  From the bootstrap node, you can retrieve the
password as:

```
ubuntu@bcpc-bootstrap:~/chef-bcpc$ knife data bag show configs Test-Laptop
cobbler-root-password:         abcdefgh
...
ubuntu@bcpc-bootstrap:~/chef-bcpc$ ssh ubuntu@10.0.100.11 uname -a
ubuntu@10.0.100.11's password: <type in abcdefgh>
Linux bcpc-vm1 3.2.0-41-generic #66-Ubuntu SMP Thu Apr 25 03:27:11 UTC 2013 x86_64 x86_64 x86_64 GNU/Linux
```
