bash 'placeholder for policies' do
  code <<~eos
    hdfs dfs -mkdir -p /bach_policies
    hdfs dfs -chmod 755 /bach_policies
    hdfs dfs -chown hdfs:hdfs /bach_policies
  eos
  user 'hdfs'
end
