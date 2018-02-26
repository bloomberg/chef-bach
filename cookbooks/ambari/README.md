This cookbook installs and configures Ambari Server and Views.

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
