include_recipe 'bcpc-hadoop::hadoop_config'

%w{hadoop-mapreduce-historyserver}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "hadoop-mapreduce-historyserver" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
end