# -*- mode: enh-ruby -*-
source 'https://supermarket.chef.io'

metadata

#
# Local cookbooks, inside our repository.
#
cookbook 'bach_common', path: './cookbooks/bach_common'
cookbook 'bach_krb5', path: './cookbooks/bach_krb5'
cookbook 'bach_oozie', path: './cookbooks/bach_oozie'
cookbook 'bach_repository', path: './cookbooks/bach_repository'
cookbook 'bach_spark', path: './cookbooks/bach_spark'
cookbook 'bcpc', path: './cookbooks/bcpc'
cookbook 'bcpc-hadoop', path: './cookbooks/bcpc-hadoop'
cookbook 'bcpc_jmxtrans', path: './cookbooks/bcpc_jmxtrans'
cookbook 'hannibal', path: './cookbooks/hannibal'
cookbook 'hdfsdu', path: './cookbooks/hdfsdu'
cookbook 'bcpc_kafka', path: './cookbooks/bcpc_kafka'
cookbook 'smoke-tests', path: './cookbooks/smoke-tests'
cookbook 'bach_opentsdb', path: './cookbooks/bach_opentsdb'

#
# Top-level requirements and transitive dependencies outside the
# supermarket.
#
instance_eval(File.read('Berksfile.common'))
