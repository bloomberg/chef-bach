# vim: tabstop=2:shiftwidth=2:softtabstop=2
default['hadoop_smoke_tests'] = {}
default['hadoop_smoke_tests']['app_name'] = 'Oozie-Smoke-Test-Coordinator'
default['hadoop_smoke_tests']['oozie_hosts'] = ['f-bcpc-vm2.bcpc.example.com']
default['hadoop_smoke_tests']['oozie_user'] = 'ubuntu'
default['hadoop_smoke_tests']['wf_path'] =
  'hdfs://Test-Laptop/user/ubuntu/oozie-smoke-tests/wf'
default['hadoop_smoke_tests']['carbon-line-receiver'] = '10.0.100.5'
default['hadoop_smoke_tests']['carbon-line-port'] = 2013
default['hadoop_smoke_tests']['wf']['co_path'] =
  'hdfs://Test-Laptop/user/ubuntu/oozie-smoke-tests/co'
default['hadoop_smoke_tests']['wf']['krb5_realm'] = 'BCPC.EXAMPLE.COM'
default['hadoop_smoke_tests']['wf']['rm'] = 'f-bcpc-vm2.bcpc.example.com'
default['hadoop_smoke_tests']['wf']['fs'] = 'hdfs://Test-Laptop'
default['hadoop_smoke_tests']['wf']['thrift_uris'] =
  'thrift://f-bcpc-vm2.bcpc.example.com:9083'
default['hadoop_smoke_tests']['wf']['zk_quorum'] =
  'f-bcpc-vm1.bcpc.example.com,f-bcpc-vm2.bcpc.example.com'
default['hadoop_smoke_tests']['wf']['hbase_master_princ'] =
  'hbase/_HOST@BCPC.EXAMPLE.COM'
default['hadoop_smoke_tests']['wf']['hbase_region_princ'] =
  'hbase/_HOST@BCPC.EXAMPLE.COM'
default['hadoop_smoke_tests']['wf']['hive_hmeta_princ'] =
  'hive/_HOST@BCPC.EXAMPLE.COM'
default['hadoop_smoke_tests']['wf']['hive_hserver_princ'] =
  'hive/_HOST@BCPC.EXAMPLE.COM'
