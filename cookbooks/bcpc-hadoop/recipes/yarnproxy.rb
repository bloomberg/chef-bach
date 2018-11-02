include_recipe 'bcpc-hadoop::hadoop_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

%w{hadoop-mapreduce-historyserver hadoop-yarn-proxyserver}.each do |pkg|
  package hwx_pkg_str(pkg, node[:bcpc][:hadoop][:distribution][:release]) do
      action :install
  end
end

# ensure we do not make polyinstantation directories for the yarn
node.default['bcpc']['pam_namespace']['real_home_dir_users'] += ['yarn']

hdp_select('hadoop-mapreduce-historyserver', node[:bcpc][:hadoop][:distribution][:active_release])

service "hadoop-yarn-proxyserver" do 
  action [:enable, :restart]
  supports :status => true, :restart => true, :reload => false
end

service "hadoop-yarn-historyserver" do 
  action [:enable, :restart]
  supports :status => true, :restart => true, :reload => false
  subscribes :restart, "bash[hdp-select hadoop-yarn-historyserver]", :immediate
end
