include_recipe 'bach_cluster_policy::_common'

bash 'placeholder for hbase policies' do
  code <<~eos
    hdfs dfs -mkdir -p /user/bach_policy/hbase
    hdfs dfs -chmod 755 /user/bach_policy/hbase
    hdfs dfs -chown bach_policy /user/bach_policy/hbase
  eos
  user 'hdfs'
end

hbase_workflow = File.join(Chef::Config['file_cache_path'], 'hbase-policies')

prestage_deployment = remote_directory hbase_workflow do
  source 'hbase'
  files_owner 'bach_policy'
  owner 'bach_policy'
end

execute 'upload hbase-policy to hdfs' do
  cwd prestage_deployment.path
  command "hdfs dfs -copyFromLocal * /user/bach_policy/hbase"
  user 'bach_policy'
  only_if { prestage_deployment.updated? }
end

job_properties = node['bach_policies']['hbase']['properties'].map do |name, value|
  "#{name}=#{value}"
end.join("\n")

job_properties = file File.join(hbase_workflow, 'job.properties') do
  content job_properties
  owner 'bach_policy'
end

execute 'run hbase policy enforcer' do
  command "oozie job -oozie #{node['bach_policies']['oozie_url']} "\
    "-config #{job_properties.path} -run"
  user 'bach_policy'
end
