This cookbook installs and configures Ambari Server and Ambari Views.

Requirements
============
### Ambari Requirements

To learn more about Ambari server and Ambari views, please see [latest documentation](https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.1.3/bk_ambari-views/content/ch_understanding_ambari_views.html).

For Ambari Views, it is required to add the following properties in the custom core-site

`hadoop.proxyuser.root.groups=*`

`hadoop.proxyuser.root.hosts=*`

### Cookbook Requirements
#### Platform
Ubuntu 14.04

#### Chef
chef 12.1+

#### Cookbooks
* postgresql

#### Softwares
* Java 8 which can be installed using [java cookbook](https://supermarket.chef.io/cookbooks/java). Once java is installed, make sure `node.default['ambari']['java_home']` is set with JAVA_HOME path in attributes. 

Recipes
=======
### default
It sets up ambari server repository and installed dependecy softwares.

### ambari\_server\_install
This recipe installs ambari server.

### ambari\_server\_setup
This recipe configures ambari servers and creates ambari configuration files e.g. ambari.properties

### ambari\_views\_setup
This recipe creates ambari views instance.

### postgres\_server\_embedded\_setup
This recipe installs postgresql server and client packages. It also creates ambari database, ambari database user and create ambari databaes schema.


Usage
=====

The recipes can be added to `run_list` as needed. For example to setup an ambari server with embedded postgresql. Add recipes in following order in node's `run_list`

`ambari::default, ambari::ambari_server_install, ambari::postgres_server_embedded_setup, ambari::ambari_server_setup, ambari::ambari_views_setup`

Testing
=======

A `.kitchen.yaml` file is provided.

1. Run `kitchen converge` to verify this cookbook.
2. Run `foodcritic` for lint tests
3. Run `kitchen verify` for ServerSpec tests

