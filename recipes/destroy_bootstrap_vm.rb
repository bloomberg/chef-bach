include_recipe 'bach_cluster::settings'

machine bootstrap_fqdn do
  action :destroy
end

