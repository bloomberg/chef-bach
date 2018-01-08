::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

[ hwx_pkg_str("slider", node[:bcpc][:hadoop][:distribution][:release]) ].each do |pkg|
  package pkg do
    action :upgrade
  end
end

hdp_select('slider', node[:bcpc][:hadoop][:distribution][:active_release])
