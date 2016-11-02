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

[
  # Worker/Head gems
  ['chef-rewind', '0.0.9'],
  ['chef-vault', '2.9.0'],
  ['mysql2', '0.4.4'],
  ['patron', '0.8.0'],
  ['rake-compiler', '1.0.1'],
  ['rkerberos', '0.1.5'],
  ['ruby-augeas', '0.5.0'],
  ['sequel', '4.36.0'],
  ['simple-graphite', '2.1.0'],
  ['webhdfs', '0.5.5'],
  ['wmi-lite', '1.0.0'],
  ['zabbixapi', '2.4.5'],
  ['zookeeper', '1.4.7'],

  # Bootstrap gems
  ['json','1.8.3'],
  ['cabin', '0.7.2'],
  ['fpm', '1.3.3'],
  ['builder', '3.2.2']
].each do |gem_name, gem_version|
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
