name             'bach_cluster'
maintainer       'Bloomberg LP'
maintainer_email 'compute@bloomberg.net'
license          'All rights reserved'
description      ''
long_description ''
version          '0.1.0'

#
# These are all the top-level cookbooks used by isolated chef servers
# in BACH clusters.  The bach_cluster deployment cookbook maintains
# these dependencies so we may upload them to the chef server created
# by the cookbook.
# 
# This list was derived from known roles and runlists.
#
# cat roles/*.json | grep recipe | perl -nle 's/\s//g; print' | sort -n | uniq | perl -nle 's/\"//g; s/^recipe//g; s/^.//; s/..$//; s/::.*//; print' | sort | uniq | perl -nle 'print "depends \"$_\""'
#
depends "apt"
depends "bach_bootstrap"
depends "bach_repository"
depends "bach_spark"
depends "bcpc"
depends "bcpc-hadoop"
depends "bcpc_jmxtrans"
depends "chef-client"
depends "chef-ingredient"
depends "hannibal"
depends "java"
depends "kafka"
depends "kafka-bcpc"
depends "maven"
depends "ntp"
depends "pam"
depends "ubuntu"
