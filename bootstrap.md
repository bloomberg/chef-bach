BCPC Cluster Bootstrap Overview
===============================

This repository contains a set of scripts that is useful to bootstrap a BCPC
cluster with a Chef,  and gateway server.

If you have Vagrant and installed, you can use our included
Vagrantfile and an Ubuntu 14.04 box file to provision a bootstrap node that is
able to act as the provisioning server with minimal interaction.

If you do not wish to use Vagrant or have a bare metal installation and wish to
do a manual install of the bootstrap node, you can use our `bootstrap_chef.sh`
scripts to bring a bare Ubuntu 14.04 image up as a provisioning server.

Finally, if you do not wish to use our scripts (we won't be offended), please
refer to the [manual instructions](#manual-setup-notes) at the end of this
document.

About hypervisor hosts
======================

chef-bcpc has been successfully tested on Ubuntu 14.04.

About proxies
=============

BCPC can be brought up behind a proxy. An example is given in
proxy_setup.sh in the chef-bcpc directory. To actually use a proxy
uncomment and edit the example lines. The example uses a proxy on the
hypervisor (for example your workstation or laptop) just to keep the
explanation self-contained and simple. The hypervisor is always IP
address 10.0.100.2 from the point of view of the VMs. Your proxy may
well be elsewhere on your network. If you use the hostname, instead of
the IP address of a proxy, you may need to adjust the DNS settings in
./environments/Test-Laptop.json - the default is to use Google's free
DNS servers 8.8.8.8 and 8.8.4.4 but those nameservers will not resolve
a hostname within a private network.

The default proxy setup does not configure a proxy, but it still must
define 'CURL' which is used in the subsequent scripts. The default is
CURL=curl.

If you do configure a proxy at the start of the process, there are a
couple of additional manual steps later in the process. Proxy support
in BCPC is, currently, even more of a work-in-progress than the rest
of the project.

Note also that the proxy settings are only known to work with the 
non-Vagrant method of bringing up the VMs. 

Kicking off the bootstrap process
=================================

To start off, create the vagrant machines:

```
$ ./vbox_create.sh [chef-environment]
```

This will create four VMs:
- bcpc-bootstrap (cobbler and chef server)
- bcpc-vm1
- bcpc-vm2
- bcpc-vm3

The ``[chef-environment]`` variable is optional and will default to
``Test-Laptop`` if unspecfied. This is useful if you need to create the
bootstrap node with non-default settings such as a a local APT mirror
(``node[:bcpc][:bootstrap][:mirror]``) or a local internet proxy
(``node[:bcpc][:bootstrap][:proxy]``).

If you have vagrant installed, the ``vbox_create.sh`` script will automatically
begin the provisioning of the bcpc-bootstrap node.  This may take 30-45 minutes
to complete successfully.  See below for [notes around the Vagrant
installation](#bcpc-bootstrap-creation-with-vagrant).

Once the bcpc-bootstrap node is available, the bcpc-vm images will be able to
be configured and boot via PXE.  Once the initial bootstrap process is complete
and the bcpc-vm machines are
[enrolled in Cobbler](#registering-vms-for-pxe-boot), the bcpc-vm machines
should automatically begin installation upon bootup.

In our testing, VirtualBox guest SMP makes performance significantly worse, so
it is recommended that you keep one CPU per VM.  You may also find that 2GB is
not enough for a BCPC-Headnode and wish to tweak the amount of RAM given to
any head node VM.

bcpc-bootstrap creation with Vagrant
====================================

If vagrant is locally installed, we utilize the
[vagrant box images from Canonical](http://cloud-images.ubuntu.com/vagrant/)
to provision the bootstrap node.

If you have a [local repository mirror](#setting-up-a-private-repos-mirror),
you can alter the Vagrantfile to use it when provisioning:

```
$local_mirror = "10.0.100.4"
```

You can log in to your bootstrap node from the hypervisor via:

```
$ vagrant ssh
```

After the automatic Vagrant provisioning is complete, this is a good time to
take a snapshot of your bootstrap node:

```
$ vagrant snapshot bootstrap
```

Please note that the 3 bcpc-vm nodes are enrolled in cobbler on the bootstrap
node at the end of ``vbox_create.sh``.

Please continue to [Imaging BCPC Nodes](#imaging-bcpc-nodes).


Provisioning chef-server without Vagrant
----------------------------------------

I *think* you have to fix up the preseed file
(cookbooks/bcpc/templates/default/cobbler.bcpc_ubuntu_host.preseed.erb)
here if using a proxy (for now explained in diff format) :
```
 d-i     mirror/country string manual
 d-i     mirror/http/hostname string <%= @node[:bcpc][:bootstrap][:mirror] %>
 d-i     mirror/http/directory string /ubuntu
-d-i     mirror/http/proxy string
 d-i     apt-setup/security_host <%= @node[:bcpc][:bootstrap][:mirror] %>
 d-i     apt-setup/security_path string /ubuntu
 <% end %>
 
+d-i     mirror/http/proxy string http://10.0.100.2:3128
+
 d-i     debian-installer/allow_unauthenticated  string false
 d-i     pkgsel/upgrade  select safe-upgrade
 d-i     pkgsel/language-packs   multiselect
```

Once you can SSH in to the bcpc-bootstrap node (ssh ubuntu@10.0.100.3 if
following instructions above), you can then run the bootstrap_chef.sh script
from the hypervisor running VirtualBox:

```
$ ./bootstrap_chef.sh ubuntu 10.0.100.3
```

This will bring up the chef-server on https://10.0.100.3.

At this point, your bootstrap node should be appropriately provisioned.

This is a good time to take a snapshot of your bootstrap node:

```
$ vagrant snapshot bootstrap chef-server-provisioned
```

Assigning roles to VM
=====================

If using a proxy, the bcpc-vm VMs will need some initial configuration
for wget before they can be 'knife bootstrap'ed. To do this, setup a
.wgetrc in the ubuntu home dir on each bcpc-vm to look like this
(using the example of a proxy on the hypervisor) :

http_proxy = http://10.0.100.2:3128/

At this point, from the bootstrap node you can then run:
```
vagrant@bootstrap:~/chef-bcpc$ ./cluster-assign-roles.sh Test-Laptop basic bcpc-vm1
vagrant@bootstrap:~/chef-bcpc$ ./cluster-assign-roles.sh Test-Laptop basic bcpc-vm2
vagrant@bootstrap:~/chef-bcpc$ ./cluster-assign-roles.sh Test-Laptop basic bcpc-vm3
```

Boostrapping these nodes will take quite a long time - as much as an
hour or more. You can monitor progress by logging into the VMs and
using tools such as 'top' or 'ps'.

Setting up a private repos mirror
=================================

If you do a lot of installations or are on an isolated network, you may wish to
utilize a private mirror.  Currently, this will require about 100GB of local
storage.

If you're using a proxy, then create ~ubuntu/.wgetrc something like this:

```
http_proxy = http://proxy.example.com:80
```

and then do this :

```
vagrant@bootstrap:~$ knife node run_list add \`hostname -f\` 'recipe[bcpc::apache-mirror]'
vagrant@bootstrap:~$ sudo chef-client
vagrant@bootstrap:~$ sudo apt-mirror /etc/apt/mirror.list
```

After successfully downloading the repository mirrors, you will then need to
edit the local environment - the following patch highlights the necessary
settings:

```
diff --git a/environments/Test-Laptop.json b/environments/Test-Laptop.json
index d844783..9a9e53a 100644
--- a/environments/Test-Laptop.json
+++ b/environments/Test-Laptop.json
@@ -28,12 +28,27 @@
         "interface" : "eth0",
         "pxe_interface" : "eth1",
         "server" : "10.0.100.3",
+        "mirror" : "10.0.100.3",
         "dhcp_subnet" : "10.0.100.0",
         "dhcp_range" : "10.0.100.10 10.0.100.250"
       },
+      "repos": {
+        "rabbitmq": "http://10.0.100.3/rabbitmq",
+        "mysql": "http://10.0.100.3/percona",
+        "hwraid": "http://10.0.100.3/hwraid"
+      },
       "ntp_servers" : [ "0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org", "3.pool.ntp.org" ],
       "dns_servers" : [ "8.8.8.8", "8.8.4.4" ]
     },
+    "ubuntu": {
+      "archive_url": "http://10.0.100.3/ubuntu",
+      "security_url": "http://10.0.100.3/ubuntu",
+      "include_source_packages": false
+    },
     "chef_client": {
       "server_url": "http://10.0.100.3:4000",
       "cache_path": "/var/chef/cache",
```

When you change or add an environment file like this, you only need to rerun the 'knife environment' 
command and then chef-client once again. Scripting this adjustment is TODO. Rerunning the entire bootstrap_chef.sh 
script at this stage is not recommended.

Manual setup notes
==================

This records notes if you do not wish to use Vagrant or our included shell
scripts to provision the bootstrap nodes.

Step 1 - One-time setup
----------------------

Install chef-dk via an Omnibus installer like
https://omnitruck.chef.io/install.sh.

```
curl -s https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chefdk -v 1.2.22
```

Build and deploy cookbooks

```
berks install
berks vendor vendor/cookbooks
```

You also need to build the installer bins for a number of external
dependencies, and there's a script to help (tested on Ubuntu 14.04)

```
 $ ./build_bins.sh
```

Step 2 - Prep the servers
----------------------

After you've set up your own environment file, get everything up to your
chef server:

```
 $ knife environment from file environments/*.json  
 $ knife role from file roles/*.json  
 $ knife cookbook upload -a
```
