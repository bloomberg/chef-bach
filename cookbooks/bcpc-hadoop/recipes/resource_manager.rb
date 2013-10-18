
%w{hadoop-yarn-resourcemanager hadoop-client}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "hadoop-yarn-resourcemanager" do
  action [:enable, :restart]
end


