Overview
========

This is a set of [Chef](https://github.com/opscode/chef) cookbooks to bring up
[Hadoop](http://hadoop.apache.org/) and [Kafka](http://kafka.apache.org)
clusters. In addition, there are a number of additional services provided with
these cookbooks - such as DNS, metrics, and monitoring - see below for a partial
list of services provided by these cookbooks.

Hadoop
------

Each Hadoop head node is Hadoop component specific. The roles are intended to
be run so that they can be layered in a highly-available manner. E.g. multiple
BCPC-Hadoop-Head-``*`` machines will correctly build a MySQL, Zookeeper, HDFS
JournalNode, etc. cluster and deploy the named component as well. Further,
for components which support HA, the intention is one can simply add the
role to multiple machines and the right thing will be done to support HA
(except in the case of HDFS).

To setup HDFS HA, please follow the following model from your Bootstrap VM:
* Install the cluster once with a non-HA HDFS:
  - with a BCPC-Hadoop-Head-Namenode-NoHA role
  - with the following node variable [:bcpc][:hadoop][:hdfs][:HA] = false
  - ensure at least three machines are installed with BCPC-Hadoop-Head roles
  - ensure at least one machine is a datanode
  - run ``cluster-assign-roles.sh <Environment> Hadoop`` successfully
* Re-configure the cluster with an HA HDFS:
  - change the BCPC-Hadoop-Head-Namenode-NoHA machine's role to
    BCPC-Hadoop-Head-Namenode
  - set the following node variable [:bcpc][:hadoop][:hdfs][:HA] = true on
    all nodes (e.g. in the environment)
  - run ``cluster-assign-roles.sh <Environment> Hadoop`` successfully

Setup
=====

These recipes are currently intended for building a BACH cluster on top of
Ubuntu 12.04 servers using Chef 11. When setting this up in VMs, be sure to
add a few dedicated disks (for HDFS data nodes) aside from boot volume. In
addition, it's expected that you have three separate NICs per machine, with
the following as defaults (and recommendations for VM settings):
 - ``eth0`` - management traffic (host-only NIC in VM)
 - ``eth1`` - reserved traffic (host-only NIC in VM)
 - ``eth2`` - compute traffic (host-only NIC in VM)

You should look at the various settings in ``cookbooks/bcpc/attributes/default.rb``
and tweak accordingly for your setup (by adding them to an environment file).

Cluster Bootstrap
-----------------

The provided scripts which sets up a Chef and Cobbler server via
[Vagrant](http://www.vagrantup.com/) permits imaging of the cluster via PXE.

Once the Chef server is set up, you can bootstrap any number of nodes to get
them registered with the Chef server for your environment - see the next
section for enrolling the nodes.

Make a cluster
--------------

To build a new BACH cluster, you have to start with building head nodes
first. (This assumes that you have already completed the bootstrap process and
have a Chef server available.)  Since the recipes will automatically generate
all passwords and keys for this new cluster, the nodes must temporarily become
``admin``'s in the chef server, so that the recipes can write the generated info
to a databag.  The databag will be called ``configs`` and the databag item will
be the same name as the environment (``Test-Laptop`` in this example). You only
need to leave the node as an ``admin`` for the first chef-client run. You can
also manually create the databag & item (as per the example in
``data_bags/configs/Example.json``) and manually upload it if you'd rather not
bother with the whole ``admin`` thing for the first run.

To assign machines a role, one can update the ``cluster.txt`` file and ensure
all necessary information is provided as per [cluster-readme.txt](./cluster-readme.txt).

Using the script [tests/automated_install.sh](./tests/automated_install.sh),
one can run through what is the expected "happy-path" install for a single
machine running (by default) four VirtualBox VMs. This simple install supports
only changing DNS, proxy and VM resource settings. (This is the basis of our
automated build tests.)

Other Deployment Flavors
------------------------

In addition to the "happy-path" integration test using `automated_install.sh` there are ways to deploy on OpenStack or to bare-metal hosts. Lastly, for those using [test-kitchen](http://kitchen.ci/) there are various test-kitchen [suites](./.kitchen.yml) one can run as well.

A view of the various full-cluster deployment types:
![Flow Chart of BACH Deployment Flavors -- VBox, OpenStack, Vagrant Bootstrap/Baremetal, Baremetal Only][bach_deployments]

Using a BACH cluster
--------------------

Once the nodes are configured and bootstrapped, BACH services will be
accessible via the floating IP.  (For the Test-Laptop environment, it is
10.0.100.5.)

For example, you can go to ``https://10.0.100.5:8888`` for the Graphite
web interface.  To find the automatically-generated service credentials, look
in the data bag for your environment.

```
ubuntu@bcpc-bootstrap:~$ knife data bag show configs Test-Laptop | grep mysql-root-password
mysql-root-password:       abcdefgh
```

For example, to check on ``HDFS``:

```
ubuntu@bcpc-vm1:~$ HADOOP_USER_NAME=hdfs hdfs dfsadmin -report
Configured Capacity: 40781217792 (37.98 GB)
Present Capacity: 40114298221 (37.36 GB)
DFS Remaining: 39727463789 (37.00 GB)
DFS Used: 386834432 (368.91 MB)
DFS Used%: 0.96%
Under replicated blocks: 0
Blocks with corrupt replicas: 0
Missing blocks: 0

-------------------------------------------------
Live datanodes (1):

Name: 192.168.100.13:50010 (f-bcpc-vm3.bcpc.example.com)
Hostname: bcpc-vm3.bcpc.example.com
Decommission Status : Normal
Configured Capacity: 40781217792 (37.98 GB)
DFS Used: 386834432 (368.91 MB)
Non DFS Used: 666919571 (636.02 MB)
DFS Remaining: 39727463789 (37.00 GB)
DFS Used%: 0.95%
DFS Remaining%: 97.42%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 12
Last contact: Fri Aug 14 21:08:23 EDT 2015
```

BACH Services
-------------

BACH currently relies upon a number of open-source packages:

 - [Apache Bigtop](http://bigtop.apache.org/)
 - [Apache Hadoop](http://hadoop.apache.org/)
 - [Apache Spark](http://spark.apache.org/)
 - [Apache HBase](http://hbase.apache.org/)
 - [Apache Hive](http://hive.apache.org/)
 - [Apache HTTP Server](http://httpd.apache.org/)
 - [Apache Mahout](http://mahout.apache.org/)
 - [Apache Oozie](http://oozie.apache.org/)
 - [Apache Pig](http://pig.apache.org/)
 - [Apache Phoenix](http://phoenix.apache.org)
 - [Apache Sqoop](http://sqoop.apache.org/)
 - [Apache Tez](http://tez.apache.org)
 - [Apache Zookeeper](http://zookeeper.apache.org)
 - [Sentric Hannibal](https://github.com/sentric/hannibal/)
 - [Twitter HDFS-DU](https://github.com/twitter/hdfs-du)
 - [Chef](http://www.getchef.com/chef/)
 - [Cobbler](http://www.cobblerd.org/)
 - [Diamond](https://github.com/BrightcoveOS/Diamond)
 - [Etherboot](http://etherboot.org/)
 - [Graphite](http://graphite.readthedocs.org/en/latest/)
 - [HAProxy](http://haproxy.1wt.eu/)
 - [Keepalived](http://www.keepalived.org/)
 - [Percona XtraDB Cluster](http://www.percona.com/software/percona-xtradb-cluster)
 - [PowerDNS](https://www.powerdns.com/)
 - [Ubuntu](http://www.ubuntu.com/)
 - [Vagrant](http://www.vagrantup.com/) - Verified with version 1.2.2
 - [VirtualBox](https://www.virtualbox.org/) - >= 4.3.x supported
 - [Zabbix](http://www.zabbix.com/)

Thanks to all of these communities for producing this software!

Contributing
------------

To propose changes to Chef-BACH, please fork the [GitHub repo](https://github.com/bloomberg/chef-bach)
and issue a pull request with your proposed change. We are endeavoring to
follow the following standards:

Libraries:
* [Chef Library Recommendations](https://www.chef.io/blog/2014/03/12/writing-libraries-in-chef-cookbooks/)

All Chef Code:
* [TomDoc](http://tomdoc.org/)

Static Code Analysis:
* Warnings not increased:
  * [RuboCop](http://batsov.com/rubocop/)
  * [Foodcritic](http://acrmp.github.io/foodcritic/)
    * [Etsy rules](https://github.com/etsy/foodcritic-rules)
    * [CustomInk rules](https://github.com/customink-webops/foodcritic-rules)
* Markup Verified With:
  * JSON: `python -m json.tool <json files>`
  * XML: `xmllint --format <xml files>`
  * ERB: `erb -P -x -T '-' <erb file> | ruby -c`

Otherwise generally follow [bbatsov/ruby-style-guide](https://github.com/bbatsov/ruby-style-guide)

The GitHub workflow we follow is captured below:
![Flow Chart of GitHub Workflow from Issue or PR created to PR in progress and Code Review to Issue or PR resolved][gh_workflow]

[gh_workflow]: https://github.com/bloomberg/chef-bach/blob/pages/readme-images/GitHub%20Workflow.png "GitHub process captured in yWorks yEd flow-chart"
[bach_deployments]: https://github.com/bloomberg/chef-bach/blob/pages/readme-images/BACH%20Deployment%20Types.png "BACH deployment options in yWorks yEd diagram"
