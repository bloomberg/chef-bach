#
# Set up zookeeper configs
#
directory "/etc/zookeeper/conf.#{node.chef_environment}" do
  owner node[:bcpc][:zookeeper][:owner] 
  group node[:bcpc][:zookeeper][:group] 
  mode 00755
  action :create
  recursive true
end

bash "update-zookeeper-conf-alternatives" do
  code %Q{
    update-alternatives --install /etc/zookeeper/conf zookeeper-conf /etc/zookeeper/conf.#{node.chef_environment} 50
    update-alternatives --set zookeeper-conf /etc/zookeeper/conf.#{node.chef_environment}
  }
end

%w{zoo.cfg
  log4j.properties
  configuration.xsl
}.each do |t|
  template "/etc/zookeeper/conf/#{t}" do
    source "zk_#{t}.erb"
    mode 0644
    variables(:zk_hosts => node[:bcpc][:zookeeper][:servers])
  end
end

