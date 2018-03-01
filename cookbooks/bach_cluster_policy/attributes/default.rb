default['bach_policies']['hbase']['properties'].tap do |hbase|
  hbase['zkQuorum'] = 'f-bcpc-vm2.bcpc.example.com'
  hbase['nameNode'] = 'Test-Laptop'
  hbase['jobTracker'] = 'Test-Laptop'
  hbase['realm'] = 'BCPC.EXAMPLE.COM'
  hbase['oozie.wf.application.path'] = 'hdfs://Test-Laptop/user/bach_policy/hbase'
  # separated by commas
  # example: namespace_name:user_name,
  hbase['tenants'] = 'ubuntu:ubuntu'
end

default['bach_policies']['oozie_url'] = 'http://f-bcpc-vm2.bcpc.example.com' \
  ':11000/oozie'

default['bach_policies']['create_local_user'] = true
