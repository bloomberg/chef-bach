# yarn_env_values is made up of the env.sh settings from the node
# object: wrapper cookbook attributes, environment overrides, etc
yarn_env_values = node[:bcpc][:hadoop][:yarn][:env_sh]

# yarn_env_generated_values is a hash of values generated here in this
# recipe.  These values will be merged with the yarn_env-Values
yarn_env_generated_values = {}

if(node.run_list.expand(node.chef_environment).recipes
       .include?('bach_spark::default'))
  yarn_env_generated_values[:YARN_USER_CLASSPATH] =
    '/usr/spark/current/yarn/spark-yarn-shuffle.jar'
end
if(node.run_list.expand(node.chef_environment).recipes
        .include?('bcpc-hadoop::datanode'))
  yarn_env_generated_values[:YARN_LOGFILE] = 
    'yarn-yarn-nodemanager-$(hostname).log'
elsif(node.run_list.expand(node.chef_environment).recipes
        .include?('bcpc-hadoop::resource_manager'))
  yarn_env_generated_values[:YARN_LOGFILE] = 
    'yarn-yarn-resourcemanager-$(hostname).log'
end

complete_yarn_env_hash =
  yarn_env_generated_values.merge(yarn_env_values)

template '/etc/hadoop/conf/yarn-env.sh' do
  source 'generic_env.sh.erb'
  mode 0555
  variables(:options => complete_yarn_env_hash)
end
