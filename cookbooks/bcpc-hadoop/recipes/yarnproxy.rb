include_recipe 'bcpc-hadoop::hadoop_config'

%w{hadoop-mapreduce-historyserver hadoop-yarn-proxyserver}.each do |pkg|
  package pkg do
      action :upgrade
  end
end

service "hadoop-yarn-proxyserver" do 
  action [:enable, :restart]
  supports :status => true, :restart => true, :reload => false
end

service "hadoop-yarn-historyserver" do 
  action [:enable, :restart]
  supports :status => true, :restart => true, :reload => false
end
