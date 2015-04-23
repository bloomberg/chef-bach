#
# Set up zookeeper configs
#
directory "#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}.#{node.chef_environment}" do
  owner node[:bcpc][:hadoop][:zookeeper][:owner] 
  group node[:bcpc][:hadoop][:zookeeper][:group] 
  mode 00755
  action :create
  recursive true
end

bash "update-zookeeper-conf-alternatives" do
  code %Q{
    update-alternatives --install #{node[:bcpc][:hadoop][:zookeeper][:conf_dir]} zookeeper-conf #{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}.#{node.chef_environment} 50
    update-alternatives --set zookeeper-conf #{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}.#{node.chef_environment}
  }
  not_if "update-alternatives --query zookeeper-conf | grep #{node.chef_environment}"
end

%w{zoo.cfg
  log4j.properties
  configuration.xsl
}.each do |t|
  template "#{node[:bcpc][:hadoop][:zookeeper][:conf_dir]}/#{t}" do
    source "zk_#{t}.erb"
    mode 0644
    variables(:zk_hosts => node[:bcpc][:hadoop][:zookeeper][:servers])
  end
end
