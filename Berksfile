# -*- mode: enh-ruby -*-
source 'https://supermarket.chef.io'

metadata

#
# Local cookbooks, inside our repository.
#
cookbook 'bach_common', path: './cookbooks/bach_common'
cookbook 'bach_krb5', path: './cookbooks/bach_krb5'
cookbook 'bach_spark', path: './cookbooks/bach_spark'
cookbook 'bcpc', path: './cookbooks/bcpc'
cookbook 'bcpc-hadoop', path: './cookbooks/bcpc-hadoop'
cookbook 'bcpc_jmxtrans', path: './cookbooks/bcpc_jmxtrans'
cookbook 'hannibal', path: './cookbooks/hannibal'
cookbook 'kafka-bcpc', path: './cookbooks/kafka-bcpc'

#
# Upstream cookbooks
#
# These are all the top-level cookbooks used by isolated chef servers
# in BACH clusters.  The bach_cluster deployment cookbook maintains
# these references so we may upload them to the chef server created
# by the cookbook.
#
# This list was derived from known roles and runlists.
#
# cat roles/*.json | grep recipe | perl -nle 's/\s//g; print' | \
# sort -n | uniq | \
# perl -nle 's/\"//g; s/^recipe//g; s/^.//; s/..$//; s/::.*//; print' | \
# sort | uniq | perl -nle 'print "depends \"$_\""'
#
cookbook 'apt'
cookbook 'chef-client'
cookbook 'java'
cookbook 'maven'
cookbook 'ntp'
cookbook 'pam'
cookbook 'ubuntu'

#
# Transitive dependencies that have been forked for one reason or another.
#

# bfd is not on the supermarket
cookbook 'bfd',
  git: 'https://github.com/bloomberg/openbfdd-cookbook'

# cobblerd forked, pending destruction of earth by moon.
cookbook 'cobblerd', 
  git: 'https://github.com/bloomberg/cobbler-cookbook'

# jmxtrans 1.0+ isn't on the supermarket.
cookbook 'jmxtrans', 
  git: 'https://github.com/bijugs/jmxtrans-cookbook',
  branch: 'ver-2.0'

# 'kafka' has an entry on the supermarket, but it's the wrong cookbook.
cookbook 'kafka',
  git: 'https://github.com/mthssdrbrg/kafka-cookbook.git',
  tag: 'v2.0.2'
 
