#
# Cookbook Name:: bach_repository
# Recipe:: gems
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']
gems_dir = "#{bins_dir}/gems"

directory gems_dir do
  mode 0555
end

{
 'chef-vault' => '2.2.4',
 'mysql2' => '0.4.1',
 'patron' => '0.4.20',
 'sequel' => '4.27.0',
 'simple-graphite' => '2.1.0',
 'webhdfs' => '0.5.5',
 'wmi-lite' => '1.0.0',
 'zabbixapi' => '2.2.2',
 'zookeeper' => '1.4.7'
}.each do |gem_name, gem_version|
  execute "gem_fetch[#{gem_name}]" do
    cwd gems_dir
    command "/usr/bin/gem fetch #{gem_name} -v #{gem_version}"
    creates "#{gems_dir}/#{gem_name}-#{gem_version}.gem"
    notifies :run, 'execute[gem-generate-index]'
  end

  link "#{gems_dir}/#{gem_name}.gem" do
    to "#{gems_dir}/#{gem_name}-#{gem_version}.gem"
    notifies :run, 'execute[gem-generate-index]'
  end
end

execute 'gem-generate-index' do
  command 'gem generate_index --legacy'
  cwd bins_dir
  action :nothing
end
