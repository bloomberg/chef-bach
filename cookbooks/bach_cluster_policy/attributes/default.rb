#default['bach_policies']['hbase']['properties'].tap do |hbase|
  #hbase['zkQuorum'] = 'f-bcpc-vm2.bcpc.example.com'
  #hbase['nameNode'] = 'Test-Laptop'
  #hbase['jobTracker'] = 'Test-Laptop'
  #hbase['realm'] = 'BCPC.EXAMPLE.COM'
  #hbase['oozie.wf.application.path'] = 'hdfs://Test-Laptop/bach_policies/hbase'
  # separated by commas
  # namespace_name:user_name,
  #hbase['bach.policies.hbase.tenants'] = 'ubuntu:ubuntu'
#end

#default['bach_policies']['oozie_url'] = 'http://f-bcpc-vm2.bcpc.example.com' \
  #':11000/oozie'
