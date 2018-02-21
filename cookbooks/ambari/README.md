This cookbook installs and configures Ambari Server, Agent and Views.

TODO
====

2. define Ambari heapsize
3. take care of dependencies, i.e. OpenSSL (v1.01, build 16 or later)
5. how to get checksum info for ambari-server?
7. externalize view properties into attributes
8. HDP 2.5 does not work with this version of ambari-chef
9. TEZ view has different version naming convention, externalize with variable
10. In Ambari 2.4.2 Hive 1.5 view is failing due to https://issues.apache.org/jira/browse/AMBARI-18387

Requirements
============

Please see [latest documentation](http://docs.hortonworks.com/HDPDocuments/Ambari-2.4.2.0/bk_ambari-views/content/ch_using_ambari_views.html).

For Ambari Views, it is required to add the following properties in the custom core-site

`hadoop.proxyuser.root.groups=*`
`hadoop.proxyuser.root.hosts=*`

Dependencies
============

- https://github.com/agileorbit-cookbooks/java.git
- https://github.com/chef-cookbooks/apt

Software Dependencies
=====================
Vagrant: 1.8.6
VirtualBox: 5.1.10

Usage
=====

Add `ambari-chef::default` to your node's `run_list`.

Testing
=======

A `.kitchen.yaml` file is provided.

1. Run `kitchen converge` to verify this cookbook.
2. Run `foodcritic` for lint tests
3. Run `kitchen verify` for ServerSpec tests
4. Run `rspec --color` for ChefSpec tests

Technical Support
=================
