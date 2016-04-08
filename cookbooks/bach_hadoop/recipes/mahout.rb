::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

package hwx_pkg_str("mahout", node[:bcpc][:hadoop][:distribution][:release])
hdp_select('mahout-client', node[:bcpc][:hadoop][:distribution][:active_release])
