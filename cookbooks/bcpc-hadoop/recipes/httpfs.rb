

package "hadoop-httpfs" do
  action :upgrade
end

service "hadoop-httpfs" do
  action [:enable, :start]
end
