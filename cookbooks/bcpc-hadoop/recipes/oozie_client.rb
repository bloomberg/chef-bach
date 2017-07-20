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

oozie_url = "http://#{node[:bcpc][:management][:vip]}:" +
  node[:bcpc][:hadoop][:oozie_port].to_s

file '/etc/profile.d/oozie-url.sh' do
  mode 0555
  user 'root'
  group 'root'
  content <<-EOM
    # This file was created by Chef.
    # Local changes will be reverted.
    export OOZIE_URL=#{oozie_url}
  EOM
end
