#!/bin/bash
service glance-api       restart
service glance-registry  restart
service cinder-api       restart
service cinder-volume    restart
service cinder-scheduler restart
service nova-scheduler   restart
service nova-cert        restart
service nova-consoleauth restart
service nova-conductor   restart
# need to manually fix ceph :(
#chef-client
