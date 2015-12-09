include_recipe 'bach_cluster::settings'

machine bootstrap_fqdn do
  action :destroy
end

# Remove our knife configuration, data bags, etc.
["#{cluster_data_dir}/knife.rb",
 "#{cluster_data_dir}/bach_user.pem",
 "#{cluster_data_dir}/bach_validator.pem"].each do |target| 
  file target do
    action :delete
  end
end

directory "#{cluster_data_dir}/data_bags" do
  action :delete
  recursive true
end

directory "#{cluster_data_dir}/syntaxcache" do
  action :delete
  recursive true
end

directory cluster_data_dir do
  action :delete
end
