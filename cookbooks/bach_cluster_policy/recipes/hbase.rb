include_recipe 'bach_cluster_policy::_common'

bash 'placeholder for hbase policies' do
  code <<~eos
    hdfs dfs -mkdir -p /bach_policies/hbase
    hdfs dfs -chmod 755 /bach_policies/hbase
    hdfs dfs -chown hbase:hdfs /bach_policies/hbase
  eos
  user 'hdfs'
end

hbase_workflow = File.join(Chef::Config['file_cache_path'], 'hbase-policies')

prestage_deployment = remote_directory hbase_workflow do
  source 'hbase'
  files_owner 'hbase'
  owner 'hbase'
end

execute 'upload hbase-policy to hdfs' do
  command "hdfs dfs -copyFromLocal #{hbase_workflow}/* /bach_policies/hbase"
  user 'hbase'
  only_if { prestage_deployment.updated? }
end

job_properties = node['bach_policies']['hbase']['properties'].map do |name, value|
  "#{name}=#{value}"
end.join("\n")

job_properties = file File.join(hbase_workflow, 'job.properties') do
  content job_properties
  owner 'hbase'
end

execute 'run hbase policy enforcer' do
  command "oozie job -oozie #{node['bach_policies']['oozie_url']} "\
    "-config #{job_properties.path} -run"
  user 'hbase'
end
