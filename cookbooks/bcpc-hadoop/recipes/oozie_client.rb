# Cookbook Name : bcpc-hadoop
# Recipe Name : oozie_client
# Description : To setup oozie-client

include_recipe 'bcpc-hadoop::oozie_config'

package "oozie-client" do
   action :upgrade
end
