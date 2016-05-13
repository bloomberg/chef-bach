include_recipe 'bcpc-hadoop::yarn_env'
include_recipe 'bcpc-hadoop::yarn_schedulers'
include_recipe 'bcpc-hadoop::yarn_site'

file "/etc/hadoop/conf/yarn.exclude" do
  mode 0644
  content ''
end
