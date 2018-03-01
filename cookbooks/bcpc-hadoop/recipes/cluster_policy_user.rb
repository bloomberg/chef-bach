user 'bach_policy' do
  manage_home true
  comment 'BACH Cluster policy enforcer'
  only_if { node['bach_policies']['create_local_user'] }
end

execute 'hdfs home directory for bach_policy' do
  command "hdfs dfs -mkdir -p /user/bach_policy"
  user 'hdfs'
  only_if { node['bach_policies']['create_local_user'] }
end

execute 'chown /user/bach_policy' do
  command "hdfs dfs -chown bach_policy /user/bach_policy"
  user 'hdfs'
  only_if { node['bach_policies']['create_local_user'] }
end
