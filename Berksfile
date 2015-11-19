# -*- mode: enh-ruby -*-
source "https://supermarket.chef.io"

metadata

cookbook 'bach_bootstrap', path: "./cookbooks/bach_bootstrap"
cookbook 'bach_common', path: "./cookbooks/bach_common"
cookbook 'bach_repository', path: "./cookbooks/bach_repository"
cookbook 'bach_spark', path: "./cookbooks/bach_spark"
cookbook 'bcpc', path: "./cookbooks/bcpc"
cookbook 'bcpc-hadoop', path: "./cookbooks/bcpc-hadoop"
cookbook 'bcpc_jmxtrans', path: "./cookbooks/bcpc_jmxtrans"
cookbook 'hannibal', path: "./cookbooks/hannibal"
cookbook 'kafka-bcpc', path: "./cookbooks/kafka-bcpc"

# chef-vault from git, pending release to supermarket
cookbook 'chef-vault',
  git: 'https://github.com/chef-cookbooks/chef-vault',
  revision: 'cd45d3485b84392b46fd93e3aaeb65bf9b7ebff1'

# cobblerd forked, pending destruction of earth by moon.
cookbook 'cobblerd', 
  git: 'https://github.com/http-418/cobbler-cookbook',
  branch: 'cobbler_profile'

# jmxtrans 1.0+ isn't on the supermarket.
cookbook 'jmxtrans', 
  git: 'https://github.com/jmxtrans/jmxtrans-cookbook',
  revision: 'd8ee2396eca91ef8e0e558490bde075869b787de'

# pdns forked, pending acceptance of a PR.
cookbook 'pdns',
  git: 'https://github.com/http-418/pdns'
