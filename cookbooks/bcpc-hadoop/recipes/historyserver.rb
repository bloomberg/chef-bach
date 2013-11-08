
%w{hadoop-mapreduce-historyserver}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "hadoop-yarn-historyserver" do
  action [:enable, :start]
end


