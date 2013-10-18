
package "oozie" do 
	action :upgrade
end

service "oozie" do 
  action [:enable, :restart]
end
  

