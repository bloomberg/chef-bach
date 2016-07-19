include_recipe 'bcpc-hadoop::yarn_env'
include_recipe 'bcpc-hadoop::yarn_schedulers'
include_recipe 'bcpc-hadoop::yarn_site'

file "/etc/hadoop/conf/yarn.exclude" do
  content node["bcpc"]["hadoop"]["decommission"]["hosts"].join("\n")
  mode 0644
  owner 'yarn'
  group 'hdfs'
  only_if { !node["bcpc"]["hadoop"]["decommission"]["hosts"].nil? }
end
