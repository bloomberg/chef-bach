# -*- mode: enh-ruby -*-
source 'https://supermarket.chef.io'

metadata

# Set to "ruby" to debug and attempt fixing circular dependencies
# FIXME: Remove this guard someday. Currently we need :gecode to be able to cut
# releases.
solver ENV.fetch('BERKS_SOLVER', :gecode)

#
# Local cookbooks, inside our repository.
#
cookbook 'bach_backup', path: './cookbooks/bach_backup'
cookbook 'bach_common', path: './cookbooks/bach_common'
cookbook 'bach_krb5', path: './cookbooks/bach_krb5'
cookbook 'bach_repository', path: './cookbooks/bach_repository'
cookbook 'bach_spark', path: './cookbooks/bach_spark'
cookbook 'backup', path: './cookbooks/backup'
cookbook 'bcpc', path: './cookbooks/bcpc'
cookbook 'bcpc-hadoop', path: './cookbooks/bcpc-hadoop'
cookbook 'bcpc_jmxtrans', path: './cookbooks/bcpc_jmxtrans'
cookbook 'hannibal', path: './cookbooks/hannibal'
cookbook 'bach_hannibal', path: './cookbooks/bach_hannibal'
cookbook 'hdfsdu', path: './cookbooks/hdfsdu'
cookbook 'bcpc_kafka', path: './cookbooks/bcpc_kafka'
cookbook 'smoke-tests', path: './cookbooks/smoke-tests'
cookbook 'bach_opentsdb', path: './cookbooks/bach_opentsdb'
cookbook 'ambari', path: './cookbooks/ambari'
cookbook 'bach_ambari', path: './cookbooks/bach_ambari'
cookbook 'ambari_metrics', path: './cookbooks/ambari_metrics'
cookbook 'bach_ambari_metrics', path: './cookbooks/bach_ambari_metrics'


#
# Top-level requirements and transitive dependencies outside the
# supermarket.
#
instance_eval(File.read('Berksfile.common'))
