::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)

[hwx_pkg_str("pig", node[:bcpc][:hadoop][:distribution][:release]), "jython"].each do |pkg|
  package pkg do
    action :upgrade
  end
end
