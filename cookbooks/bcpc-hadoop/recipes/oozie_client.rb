# Cookbook Name : bcpc-hadoop
# Recipe Name : oozie_client
# Description : To setup oozie-client

include_recipe 'bcpc-hadoop::oozie_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

package hwx_pkg_str('oozie-client', node[:bcpc][:hadoop][:distribution][:release]) do
   action :install
end

hdp_select('oozie-client', node[:bcpc][:hadoop][:distribution][:active_release])
